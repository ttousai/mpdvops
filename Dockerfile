FROM python:3-alpine
WORKDIR /usr/src/app

COPY src/* ./
RUN pip install --no-cache-dir -r requirements.txt

ENV FLASK_APP=app.py

CMD ["flask", "run", "--host=0.0.0.0"]
