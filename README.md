# plantuml-to-mermaid

Convert plantuml to mermaid by shell scripts.

## Limitations

- Supporting only (basic) sequence diagram.
  - You can find what you can do in the [./samples](./samples/).
- Expecting PlantUML diagram is in markdown file and within the code block (plantuml tag).

## How to use

You need `main.sh` to run.

``` sh
$ bash main.sh <target_markdown_file>
# specify output filename
$ bash main.sh <target_markdown_file> -o <output_markdown_file>
```

## License 

"plantuml-to-mermaid" is under [GPL-3.0 License](./LICENSE).
