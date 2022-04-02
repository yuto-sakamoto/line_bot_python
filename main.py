# from re import I
from flask import Flask, request, abort

from linebot import (
    LineBotApi, WebhookHandler
)
from linebot.exceptions import (
    InvalidSignatureError
)
from linebot.models import (
    MessageEvent, TextMessage, TextSendMessage,
)
CHANNEL_SECRET = 'e4899c60877f47f311b1144c3fa65678'
CHANNEL_ACCESS_TOKEN = 'wVyd3Yk2vIHwGE5/VHAA1SiqlPtukRnE1Djrv/eMRBzNcORCzYpIFWsjhGxQe/xvANrjRKFHA7oHWmRk7UpKZ65fsQ38zsA2znD8L7RkiFIvBPwQ9D/YOtciupdxNgMIHykw+HQZaWPr5JYvQvTfMQdB04t89/1O/w1cDnyilFU='
app = Flask(__name__)
line_bot_api = LineBotApi(CHANNEL_ACCESS_TOKEN)
handler = WebhookHandler(CHANNEL_SECRET)


@app.route("/callback", methods=['POST'])
def callback():
    # get X-Line-Signature header value
    signature = request.headers['X-Line-Signature']

    # get request body as text
    body = request.get_data(as_text=True)
    app.logger.info("Request body: " + body)

    # handle webhook body
    try:
        handler.handle(body, signature)
    except InvalidSignatureError:
        print("Invalid signature. Please check your channel access token/channel secret.")
        abort(400)

    return 'OK'


@handler.add(MessageEvent, message=TextMessage)
def handle_message(event):
    line_bot_api.reply_message(
        event.reply_token,
        TextSendMessage(text=event.message.text))


if __name__ == "__main__":
    app.run()