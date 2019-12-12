import os
import sys
from pathlib import Path

from cryptography.fernet import Fernet


def decrypt_file(file_enc: Path, output: Path, verbose: bool = False) -> None:
    if verbose:
        print(f"Decrypting `{file_enc}` to `{output}`")
    assert file_enc.exists(), f"encrypted file does not exist: {file_enc}"

    with file_enc.open(mode="rb") as f_enc:
        with output.open(mode="wb") as f_dec:
            fernet = Fernet(os.environ["GCP_CONFIG_ENCRYPTION_KEY"])
            dec = fernet.decrypt(f_enc.read())
            f_dec.write(dec)

    if verbose:
        print("Decryption done")


if __name__ == "__main__":
    file_enc = Path(sys.argv[1])
    output = Path(sys.argv[2])
    decrypt_file(file_enc, output, verbose=True)
