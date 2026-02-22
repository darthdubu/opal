use criterion::{black_box, criterion_group, criterion_main, Criterion};
use opal_vte::Parser;

fn parse_simple_text(c: &mut Criterion) {
    let mut parser = Parser::new();
    let input = b"Hello, World!\nThis is a test.\n";

    c.bench_function("parse simple text", |b| {
        b.iter(|| {
            parser.reset();
            black_box(parser.parse(input))
        })
    });
}

fn parse_with_escape_sequences(c: &mut Criterion) {
    let mut parser = Parser::new();
    let input = b"\x1b[31mRed\x1b[0m \x1b[1;32mBold Green\x1b[0m\n";

    c.bench_function("parse with escape sequences", |b| {
        b.iter(|| {
            parser.reset();
            black_box(parser.parse(input))
        })
    });
}

fn parse_cursor_movement(c: &mut Criterion) {
    let mut parser = Parser::new();
    let input = b"\x1b[H\x1b[10;10H\x1b[A\x1b[B\x1b[C\x1b[D";

    c.bench_function("parse cursor movement", |b| {
        b.iter(|| {
            parser.reset();
            black_box(parser.parse(input))
        })
    });
}

criterion_group!(
    benches,
    parse_simple_text,
    parse_with_escape_sequences,
    parse_cursor_movement
);
criterion_main!(benches);
