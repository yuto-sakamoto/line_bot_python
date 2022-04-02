FROM python:3.9.6

RUN pip install line-bot-sdk flask

WORKDIR /line_bot_python
