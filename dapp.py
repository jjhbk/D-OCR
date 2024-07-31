from os import environ
import logging
from cartesi import DApp, Rollup, RollupData
from PIL import Image
import base64
import pytesseract
import json
import io

# print(pytesseract.image_to_string(Image.open('/opt/cartesi/dapp/aadhar.jpg')))


def hex_to_str(hex):
    """Decode a hex string prefixed with "0x" into a UTF-8 string"""
    return bytes.fromhex(hex[2:]).decode("utf-8")


def str_to_hex(str):
    """Encode a string as a hex string, adding the "0x" prefix"""
    return "0x" + str.encode("utf-8").hex()


def base64_to_image(base64_str):
    image_data = base64.b64decode(base64_str)
    image = Image.open(io.BytesIO(image_data))
    return image


def extract_text_from_base64(base64_str):
    image = base64_to_image(base64_str)
    text = pytesseract.image_to_string(image, lang='eng')
    return text


LOGGER = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG)
dapp = DApp()


@dapp.advance()
def handle_advance(rollup: Rollup, data: RollupData) -> bool:
    try:
        payload = data.str_payload()
        payload = json.loads(payload)
        LOGGER.debug("Echoing '%s'", payload)
        base64_string = payload["data"]
        print(payload, base64_string)
        extracted_text = extract_text_from_base64(base64_string)
        print("Extracted Text: ", extracted_text)
        final_text = json.dumps(
            {"id": payload["id"], "result": extracted_text})
        LOGGER.debug("result is: %s", final_text)
        rollup.notice("0x" + final_text.encode('utf-8').hex())
        return True
    except Exception as error:
        error_msg = f"Failed to process command '{base64_string}'. {error}"
        rollup.report("0x"+error_msg.encode('utf-8').hex())
        return False


if __name__ == '__main__':
    dapp.run()
