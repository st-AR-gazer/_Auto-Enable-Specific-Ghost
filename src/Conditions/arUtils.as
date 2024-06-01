namespace _Text {
    int LastIndexOf(const string &in str, const string &in value) {
        int lastIndex = -1;
        int index = str.IndexOf(value);
        while (index != -1) {
            lastIndex = index;
            if (index + value.Length >= str.Length) break;
            index = str.SubStr(index + value.Length).IndexOf(value);
            if (index != -1) {
                index += lastIndex + value.Length;
            }
        }
        return lastIndex;
    }
}

namespace _IO {
    string ReadFileToEnd(const string &in path) {
        if (IO::FileExists(path)) {
            IO::File file(path, IO::FileMode::Read);
            string content = file.ReadToEnd();
            file.Close();
            return content;
        }
        return "";
    }

    string GetFileName(const string &in path) {
        int index = _Text::LastIndexOf(path, "/");
        if (index == -1) {
            return path;
        }
        return path.SubStr(index + 1);
    }

    string GetFileNameWithoutExtension(const string &in path) {
        string fileName = GetFileName(path);
        int index = _Text::LastIndexOf(fileName, ".");
        if (index == -1) {
            return fileName;
        }
        return fileName.SubStr(0, index);
    }

    string GetFileExtension(const string &in path) {
        int index = _Text::LastIndexOf(path, ".");
        if (index == -1) {
            return "";
        }
        return path.SubStr(index + 1);
    }

    void OpenFolder(const string &in path) {
        if (IO::FolderExists(path)) {
            OpenExplorerPath(path);
        } else {
            log("Folder does not exist: " + path, LogLevel::Info, 62, "OpenFolder");
        }
    }
}

namespace _Json {
    string PrettyPrint(const Json::Value &in value) {
        string jsonStr = Json::Write(value);
        string pretty;
        int depth = 0;
        bool inString = false;

        for (int i = 0; i < jsonStr.Length; ++i) {
            string currentChar = jsonStr.SubStr(i, 1);

            if (currentChar == "\"") inString = !inString;

            if (!inString) {
                if (currentChar == "{" || currentChar == "[") {
                    pretty += currentChar + "\n" + Hidden::Indent(depth + 1);
                    ++depth;
                } else if (currentChar == "}" || currentChar == "]") {
                    --depth;
                    pretty += "\n" + Hidden::Indent(depth) + currentChar;
                } else if (currentChar == ",") {
                    pretty += currentChar + "\n" + Hidden::Indent(depth);
                } else if (currentChar == ":") {
                    pretty += currentChar + " ";
                } else {
                    pretty += currentChar;
                }
            } else {
                pretty += currentChar;
            }
        }

        pretty = "\n" + pretty;
        return pretty;
    }

    namespace Hidden {
        string Indent(int depth) {
            string indent;
            for (int i = 0; i < depth; ++i) {
                indent += "    ";
            }
            return indent;
        }
    }
}

namespace _Math {
    double PI = 3.14159265358979323846;
}