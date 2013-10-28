library ini;
import 'dart:async';
import 'dart:io';

/*
   This library deals with reading and writing ini files. This implements the
   standard as defined here:

   https://en.wikipedia.org/wiki/INI_file

   The ini file reader will return data organized by section and option. The
   default section will be the blank string.
*/

// Blank lines are stripped.
RegExp _re_whitespace = new RegExp(r"^\s*$");
// Comment lines start with a semicolon. This permits leading whitespace.
RegExp _re_comment = new RegExp(r"^\s*;");
// sections and entries can span lines if subsequent lines start with
// whitespace. See http://tools.ietf.org/html/rfc822.html#section-3.1
RegExp _re_long_header_field = new RegExp(r"^\s");
// sections are surrounded by square brakets. This does not trim section names.
RegExp _re_section = new RegExp(r"^\s*\[(.*\S.*)]\s*$");
// entries are made up of a key and a value. The key must have at least one non
// blank character. The value can be completely blank. This does not trim key
// or value.
RegExp _re_entry = new RegExp(r"^([^=]+)=(.*?)$");

class _Parser {
  // The stream of unparsed data
  List<String> _strings;
  // The parsed config object
  Config _config;

  /*
     Strips blank lines.
  */
  static Iterable<String> _remove_whitespace(Iterable<String> source) => source.where((String line) => ! _re_whitespace.hasMatch(line));
  /*
     Strips comment lines.
  */
  static Iterable<String> _remove_comment(Iterable<String> source) => source.where((String line) => ! _re_comment.hasMatch(line));
  /*
     Turns the lines that have been continued over multiple lines into single lines.
  */
  static List<String> _compress_long_header_fields(Iterable<String> source) {
    List<String> result = new List<String>();
    String line = '';

    for (String current in source) {
      if ( _re_long_header_field.hasMatch(current) ) {
        // The leading whitespace makes this a long header field. It is
        // not part of the value.
        line += current.replaceFirst(r"^\s*","");
      }
      else {
        if ( line != '' ) {
          result.add(line);
        }
        line = current;
      }
    }
    if ( line != '' ) {
      result.add(line);
    }

    return result;
  }

  /*
     Reduce the strings to the lines representing sections and entries and creates the parser.
  */
  _Parser(List<String> strings) {
    _strings = _compress_long_header_fields(_remove_comment(_remove_whitespace(strings)));
  }
  /*
     Splits the string on newline characters and creates the parser from it.
  */
  _Parser.fromString(String string) : this(string.split(new RegExp(r"[\r\n]+")));
  /*
     Reduce the strings to the lines representing sections and entries and creates the parser.
  */
  static Future<_Parser> fromStream(Stream<String> stream) =>
      stream.toList().then((List<String> strings) => new _Parser(strings));
  /*
     Reads the file and creates the parser from the content.
  */
  static Future<_Parser> readFile(File file) =>
    file.readAsLines().then((List<String> strings) => new _Parser(strings));
  /*
     Reads the file and creates the parser from the content.
  */
  static _Parser readFileSync(File file) =>
    new _Parser(file.readAsLinesSync());

  /*
     Creates a Config from the cleaned list of strings.
  */
  Config _parse() {
    Config result = new Config();
    String section = 'default';

    for (String current in _strings) {
      Match is_section = _re_section.firstMatch(current);
      if ( is_section != null ) {
        section = is_section[1].trim();
        result.add_section(section);
      }
      else {
        Match is_entry = _re_entry.firstMatch(current);
        if ( is_entry != null ) {
          result.set(section, is_entry[1].trim(), is_entry[2].trim());
        }
        else {
          throw new Exception('Unrecognized line: "${current}"');
        }
      }
    }

    return result;
  }

  /*
     Returns the Config that has been parsed. The first call will trigger the
     parse.
  */
  get config {
    if ( _config == null ) {
      _config = this._parse();
    }
    return _config;
  }
}

class Config {
  // The defaults consist of all entries that are not within a section.
  Map<String, String> _defaults = new Map<String, String>();
  // The sections contains all entries organized by section.
  Map<String, Map<String, String>> _sections = new Map<String, Map<String, String>>();

  /*
     Create a blank config.
  */
  Config();
  /*
     Load a Config from the provided string.
  */
  factory Config.fromString(String string) {
    return new _Parser.fromString(string).config;
  }
  /*
     Load a Config from the provided strings. It is assumed that the strings
     have been split on new lines.
  */
  factory Config.fromStrings(List<String> strings) {
    return new _Parser(strings).config;
  }
  /*
     Load a Config from the provided file.
  */
  static Future<Config> readFile(File file) {
    return _Parser.readFile(file).then((_Parser parser) => parser.config);
  }
  /*
     Load a Config from the provided file.
  */
  static Config readFileSync(File file) {
    return _Parser.readFileSync(file).config;
  }

  /*
     Write this Config to the file.
  */
  Future<File> writeFile(File file) {
    return file.writeAsString(toString());
  }
  /*
     Write this Config to the file.
  */
  void writeFileSync(File file) {
    file.writeAsStringSync(toString());
  }

  /*
     Convert the Config to a parseable string version.
  */
  String toString() {
    StringBuffer buffer = new StringBuffer();

    buffer.writeAll(items('default').map((e) => "${e[0]} = ${e[1]}"), "\n");
    buffer.write("\n");
    for (String section in sections()) {
      buffer.write("[${section}]\n");
      buffer.writeAll(items(section).map((e) => "${e[0]} = ${e[1]}"), "\n");
      buffer.write("\n");
    }

    return buffer.toString();
  }

  /*
     Returns the section or null if the section does not exist. The string
     'default' (case insensitive) will return the default section.
  */
  Map<String, String> _get_section(String section) {
    if ( section.toLowerCase() == 'default' ) {
      return _defaults;
    }
    if ( _sections.containsKey(section) ) {
      return _sections[section];
    }
    return null;
  }

  /*
     Return a dictionary containing the instance-wide defaults.
  */
  Map<String, String> defaults() => _defaults;

  /*
     Return a list of the sections available; DEFAULT is not included in the list.
  */
  Iterable<String> sections() => _sections.keys;

  /*
     Add a section named section to the instance. If a section by the given
     name already exists, DuplicateSectionError is raised. If the name DEFAULT
     (or any of it’s case-insensitive variants) is passed, ValueError is
     raised.
  */
  void add_section(String section) {
    if ( section.toLowerCase() == 'default' ) {
      throw new Exception('ValueError');
    }
    if ( _sections.containsKey(section) ) {
      throw new Exception('DuplicateSectionError');
    }
    _sections[section] = new Map<String, String>();
  }

  /*
     Indicates whether the named section is present in the configuration. The
     DEFAULT section is not acknowledged
  */
  bool has_section(String section) => _sections.containsKey(section);

  /*
     Returns a list of options available in the specified section.
  */
  Iterable<String> options(String section) {
    Map<String,String> s = this._get_section(section);
    return s != null ? s.keys : null;
  }

  /*
     If the given section exists, and contains the given option, return True;
     otherwise return False
  */
  bool has_option(String section, option) {
    Map<String,String> s = this._get_section(section);
    return s != null ? s.containsKey(option) : false;
  }

  /*
     Get an option value for the named section.
  */
  String get(String section, option) {
    Map<String,String> s = this._get_section(section);
    return s != null ? s[option] : null;
  }

  /*
     Return a list of (name, value) pairs for each option in the given
     section
  */
  List<List<String>> items(String section) {
    Map<String,String> s = this._get_section(section);
    return s != null ? s.keys.map((String key) => [key, s[key]]).toList() : null;
  }

  /*
     If the given section exists, set the given option to the specified value;
     otherwise raise NoSectionError.
  */
  void set(String section, option, value) {
    Map<String,String> s = this._get_section(section);
    if ( s == null ) {
      throw new Exception('NoSectionError');
    }
    s[option] = value;
  }

  /*
     Remove the specified option from the specified section. If the section
     does not exist, raise NoSectionError. If the option existed to be removed,
     return True; otherwise return False
  */
  bool remove_option(String section, option) {
    Map<String,String> s = this._get_section(section);
    if ( s != null ) {
      if ( s.containsKey(option) ) {
        s.remove(option);
        return true;
      }
      return false;
    }
    throw new Exception('NoSectionError');
  }

  /*
      Remove the specified section from the configuration. If the section in
      fact existed, return True. Otherwise return False
  */
  bool remove_section(String section) {
    if ( section.toLowerCase() == 'default' ) {
      // Can't add the default section, so removing is just clearing.
      _defaults.clear();
    }
    if ( _sections.containsKey(section) ) {
      _sections.remove(section);
      return true;
    }
    return false;
  }
}

// vim: set ai et sw=2 syntax=dart :
