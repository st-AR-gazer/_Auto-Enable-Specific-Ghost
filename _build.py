import os
import zipfile

def zip_directory(src_dir, zip_file):
    for root, dirs, files in os.walk(src_dir):
        for file in files:
            file_path = os.path.join(root, file)
            zip_file.write(file_path, os.path.relpath(file_path, os.path.join(src_dir, '..')))

def create_op_file():
    top_dir_name = os.path.basename(os.getcwd())
    op_file_name = f"{top_dir_name}.op"

    with zipfile.ZipFile(op_file_name, 'w', zipfile.ZIP_DEFLATED) as zipf:
        zip_directory('./src', zipf)

        additional_files = ['info.toml', 'LICENSE', 'README.md']
        for file in additional_files:
            if os.path.exists(file):
                zipf.write(file)

    print(f"Created {op_file_name} successfully.")

if __name__ == "__main__":
    create_op_file()
