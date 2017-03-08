#if SWIFT_PACKAGE
import CYaml
#endif
import Foundation

public enum YamlError: Swift.Error {
    // Used in `yaml_emitter_t` and `yaml_parser_t`
    /// YAML_NO_ERROR. No error is produced.
    case no
    /// YAML_MEMORY_ERROR. Cannot allocate or reallocate a block of memory.
    case memory

    // Used in `yaml_parser_t`
    /// YAML_READER_ERROR. Cannot read or decode the input stream.
    case reader(problem: String, byteOffset: Int, value: Int32)

    // line and column start from 0, column is counted by unicodeScalars
    /// YAML_SCANNER_ERROR. Cannot scan the input stream.
    case scanner(context: String, problem: String, line: Int, column: Int)
    /// YAML_PARSER_ERROR. Cannot parse the input stream.
    case parser(context: String?, problem: String, line: Int, column: Int)
    /// YAML_COMPOSER_ERROR. Cannot compose a YAML document.
    case composer(context: String?, problem: String, line: Int, column: Int)

    // Used in `yaml_emitter_t`
    /// YAML_WRITER_ERROR. Cannot write to the output stream.
    case writer(problem: String)
    /// YAML_EMITTER_ERROR. Cannot emit a YAML stream.
    case emitter(problem: String)
}

extension YamlError {
    init(from parser: yaml_parser_t) {
        switch parser.error {
        case YAML_MEMORY_ERROR:
            self = .memory
        case YAML_READER_ERROR:
            self = .reader(problem: String(cString: parser.problem),
                           byteOffset: parser.problem_offset,
                           value: parser.problem_value)
        case YAML_SCANNER_ERROR:
            self = .scanner(context: parser.context != nil ? String(cString: parser.context) : "",
                            problem: String(cString: parser.problem),
                            line: parser.problem_mark.line,
                            column: parser.problem_mark.column)
        case YAML_PARSER_ERROR:
            self = .parser(context: parser.context != nil ? String(cString: parser.context) : nil,
                             problem: String(cString: parser.problem),
                             line: parser.problem_mark.line,
                             column: parser.problem_mark.column)
        case YAML_COMPOSER_ERROR:
            self = .composer(context: parser.context != nil ? String(cString: parser.context) : nil,
                             problem: String(cString: parser.problem),
                             line: parser.problem_mark.line,
                             column: parser.problem_mark.column)
        default:
            fatalError("Parser has unknown error: \(parser.error)!")
        }
    }

    init(from emitter: yaml_emitter_t) {
        switch emitter.error {
        case YAML_MEMORY_ERROR:
            self = .memory
        case YAML_EMITTER_ERROR:
            self = .emitter(problem: String(cString: emitter.problem))
        default:
            fatalError("Emitter has unknown error: \(emitter.error)!")
        }
    }
}

extension YamlError {
    public func describing(with yaml: String) -> String {
        switch self {
        case .no:
            return "No error is produced"
        case .memory:
            return "Memory error"
        case let .reader(problem, byteOffset, value):
            #if USE_UTF8
                guard let (_, column, contents) = yaml.utf8LineNumberColumnAndContents(at: byteOffset)
                    else { return "\(problem) at byte offset: \(byteOffset), value: \(value)" }
            #else
                guard let (_, column, contents) = yaml.utf16LineNumberColumnAndContents(at: byteOffset / 2)
                    else { return "\(problem) at byte offset: \(byteOffset), value: \(value)" }
            #endif
            return contents.endingWithNewLine
                + String(repeating: " ", count: column - 1) + "^ " + problem
        case let .scanner(context, problem, line, column):
            return describing(with: yaml, context, problem, line, column)
        case let .parser(context, problem, line, column):
            return describing(with: yaml, context ?? "", problem, line, column)
        case let .composer(context, problem, line, column):
            return describing(with: yaml, context ?? "", problem, line, column)
        default:
            fatalError("unreachable")
        }
    }

    private func describing(with yaml: String,
                            _ context: String,
                            _ problem: String,
                            _ line: Int,
                            _ column: Int // libYAML counts column by unicodeScalars.
        ) -> String {
        let contents = yaml.substring(at: line)
        let columnIndex = contents.unicodeScalars
            .index(contents.unicodeScalars.startIndex,
                   offsetBy: column,
                   limitedBy: contents.unicodeScalars.endIndex)?
            .samePosition(in: contents) ?? contents.endIndex
        let column = contents.distance(from: contents.startIndex, to: columnIndex)
        return contents.endingWithNewLine +
            String(repeating: " ", count: column) + "^ " + problem + " " + context
    }
}
