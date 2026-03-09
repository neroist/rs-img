use std::fs;
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::ptr;
use std::time::Instant;

use cl3::types::CL_NON_BLOCKING;
use clap::*;
use image::*;
use indicatif::*;
use itertools::Itertools;
use mathexpr::{parse, BinOp, EvalError, Expr};
use opencl3::command_queue::{CommandQueue, CL_QUEUE_PROFILING_ENABLE};
use opencl3::context::Context;
use opencl3::device::{Device, CL_DEVICE_TYPE_GPU};
use opencl3::kernel::{ExecuteKernel, Kernel};
use opencl3::memory::{Buffer, CL_MEM_READ_ONLY};
use opencl3::platform;
use opencl3::program::Program;
use opencl3::types::cl_uchar;

#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

    /// Expression to graph
    expr: String,

    /// Image/video output file
    #[arg(short, long, value_name = "FILE")]
    output: PathBuf,

    /// Resolution of the resulting image/video
    #[arg(short, long, default_value = "1024")]
    size: usize,

    /// Distance of the origin from the sides of the image
    #[arg(short, long, default_value = "1")]
    radius: usize,
}

#[derive(Subcommand)]
enum Commands {
    /// Animate a graph over time using the parametric variable t
    Anim {
        /// Fps of the animation
        #[arg(short, long, default_value = "60")]
        fps: usize,

        /// Length of the animation, in seconds
        #[arg(short, long, default_value = "5")]
        length: usize,
    },
}

/// Converts math expression ast to an OpenCL C expression
#[allow(clippy::needless_return, clippy::redundant_field_names)]
fn ast_to_opencl(ast: Expr) -> Result<String, EvalError> {
    let binops = ["cadd", "csub", "cmul", "cdiv", "", "cpow"];
    let funcs = [
        "real", "re", "imag", "im", "abs", "mod", "modulus", "norm", "arg", "phase", "conj",
        "proj", // "polar", "cis",
        "exp", "log", "ln", "log2", "log10", "logbase", "pow", "sqrt", "cbrt", "sin", "cos", "tan",
        "asin", "acos", "atan", "sinh", "cosh", "tanh", "asinh", "acosh", "atanh",
    ];
    let binary_funcs = ["logbase", "pow", "proj"];

    match ast {
        Expr::Number(val) => return Ok(format!("(cdouble)({},0)", val)),
        Expr::Variable(var) => match var.to_ascii_lowercase().as_str() {
            "z" => return Ok("z".to_string()),
            "t" => return Ok("(cdouble)(t,0)".to_string()),
            "i" => return Ok("M_I".to_string()),
            "e" => return Ok("M_E".to_string()),
            "pi" => return Ok("M_PI".to_string()),
            "tau" => return Ok("M_TAU".to_string()),
            "phi" => return Ok("M_PHI".to_string()),
            _ => {
                return Err(EvalError::UnknownVariable(format!(
                    "Unknown variable '{}'",
                    var
                )))
            }
        },
        Expr::BinaryOp { op, left, right } => {
            if op == BinOp::Mod {
                return Err(EvalError::UnknownFunction(
                    "Modulus operator is not supported!".to_string(),
                ));
            }

            return Ok(format!(
                "{}({}, {})",
                binops[op as usize],
                ast_to_opencl(*left)?,
                ast_to_opencl(*right)?
            ));
        }
        Expr::UnaryMinus(expr) => return Ok(format!("-{}", ast_to_opencl(*expr)?)),
        Expr::FunctionCall { name, args } => {
            // handle unknown functions
            if !funcs.contains(&name.as_str()) {
                return Err(EvalError::UnknownFunction(format!(
                    "Unknown function '{}'",
                    name
                )));
            }

            // handle incorrect arity
            let expected_arity = if binary_funcs.contains(&name.as_str()) {
                2
            } else {
                1
            };

            if args.len() != expected_arity {
                return Err(EvalError::WrongArity {
                    name: name,
                    expected: expected_arity,
                    got: args.len(),
                });
            }

            // handle errors in function arguments
            // ! fix the `.clone()`s
            let map = args.iter().map(|x| ast_to_opencl(x.clone()));
            if let Some(err) = map.clone().find(|x| x.is_err()) {
                return err;
            }

            return Ok(format!(
                "c{}({})",
                name.to_ascii_lowercase(),
                map.map(|x| x.unwrap()).join(", ")
            ));
        }
        _ => return Ok("".to_string()),
    };
}

#[allow(clippy::zombie_processes)]
fn main() -> opencl3::Result<()> {
    let mut cli = Cli::parse();

    let expr = parse(cli.expr.as_str()).expect("Failed to parse expression!");

    const CLCOMPLEX: &str = include_str!("./clcomplex.cl");
    const MAIN: &str = include_str!("./main.cl");
    let func = format!(
        "cdouble f(cdouble z, double t) {{ return {}; }}",
        ast_to_opencl(expr).unwrap()
    );
    let source = [CLCOMPLEX, MAIN, func.as_str()].join("\n\n");

    const KERNEL_NAME: &str = "colorize";
    let options = format!("-cl-std=CL2.0 -DCOMPILING -DP_RADIUS={}", cli.radius);

    let width: usize = cli.size;
    let height: usize = cli.size;
    // ! If you're wondering why we add 1 here: currently, there is a bug
    // where only the first image generated is pure white. Thus, we skip
    // it and add an extra image to compensate
    let layers: usize = match cli.command {
        Some(Commands::Anim { fps, length }) => fps * length + 1,
        None => 2,
    };

    // Find a usable platform and device for this application
    let platforms = platform::get_platforms()?;
    let platform = platforms.first().expect("no OpenCL platforms");
    let device = *platform
        .get_devices(CL_DEVICE_TYPE_GPU)?
        .first()
        .expect("no device found in platform");
    let device = Device::new(device);

    // Create a Context on an OpenCL device
    let context = Context::from_device(&device).expect("Context::from_device failed");

    // Build the OpenCL program source and create the kernel.
    let program =
        Program::create_and_build_from_source(&context, source.as_str(), options.as_str())
            .expect("Program::create_and_build_from_source failed");
    let kernel = Kernel::create(&program, KERNEL_NAME).expect("Kernel::create failed");

    // Create a command_queue on the Context's device
    let queue =
        CommandQueue::create_default_with_properties(&context, CL_QUEUE_PROFILING_ENABLE, 0)
            .expect("CommandQueue::create_default_with_properties failed");

    // Create an buffer
    let buf = unsafe {
        Buffer::<cl_uchar>::create(
            &context,
            CL_MEM_READ_ONLY,
            width * height * layers * 3,
            ptr::null_mut(),
        )?
    };

    // Run the kernel on the input data
    let kernel_event = unsafe {
        ExecuteKernel::new(&kernel)
            .set_arg(&buf)
            .set_global_work_sizes(&[width, height, layers])
            .enqueue_nd_range(&queue)?
    };

    let events = vec![kernel_event.get()];

    // Read the image data from the device
    let mut image_data: Vec<u8> = vec![0; width * height * layers * 3];
    let read_event =
        unsafe { queue.enqueue_read_buffer(&buf, CL_NON_BLOCKING, 0, &mut image_data, &events)? };

    // Wait for the read_event to complete.
    read_event.wait()?;

    // Save image to disk
    if cli.command.is_none() {
        if cli.output.extension().is_none() {
            cli.output.add_extension("png");
        }

        let img = RgbImage::from_raw(
            width as u32,
            height as u32,
            image_data[(width * height * 3)..2 * (width * height * 3)].to_vec(),
        )
        .unwrap();
        img.save(cli.output).unwrap();

        return Ok(());
    }

    // Save video to disk
    let pb = ProgressBar::new(layers as u64);
    pb.set_style(
        ProgressStyle::default_bar()
            .template("[{elapsed_precise}] [{wide_bar:.cyan/blue}] {pos}/{len}")
            .unwrap()
            .progress_chars("##-"),
    );

    let start = Instant::now();

    // We begin by writing all the frames to disk

    // set up blank imgs dir
    if fs::exists("imgs").unwrap() {
        fs::remove_dir_all("imgs").expect("Failed to delete directory")
    }
    fs::create_dir("imgs").unwrap();
    for i in 1..layers {
        pb.inc(1);
        let img = RgbImage::from_raw(
            width as u32,
            height as u32,
            image_data[i * (width * height * 3)..(i + 1) * (width * height * 3)].to_vec(),
        )
        .unwrap();
        img.save_with_format(format!("./imgs/{:0>4}.tiff", i), image::ImageFormat::Tiff)
            .expect("failed to save image");
    }
    pb.finish_and_clear();
    println!("Done! Took {}ms", start.elapsed().as_millis());

    // Then, we ask ffmpeg to bundle it all up into a video for us
    let _ = Command::new("ffmpeg")
        .args([
            "-y",
            "-loglevel", "quiet",
            "-framerate", "60",
            "-i", "imgs/%04d.tiff",
        ])
        .arg(cli.output.to_str().unwrap())
        .stdout(Stdio::piped())
        .spawn()
        .expect("Failed to start ffmpeg");

    Ok(())
}
