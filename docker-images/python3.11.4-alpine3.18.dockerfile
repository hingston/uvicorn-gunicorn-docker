FROM python:3.11.4-alpine3.18 as base

FROM base as builder
COPY requirements.txt /tmp/requirements.txt
RUN apk add --no-cache --virtual .build-deps gcc libc-dev make \
    && python3 -m pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/app/wheels -r /tmp/requirements.txt \
    && apk del .build-deps gcc libc-dev make

FROM base as final
RUN apk update && apk upgrade
COPY --from=builder /usr/src/app/wheels /wheels
RUN pip install --no-cache /wheels/*
COPY ./start.sh /start.sh
RUN chmod +x /start.sh
COPY ./gunicorn_conf.py /gunicorn_conf.py
COPY ./start-reload.sh /start-reload.sh
RUN chmod +x /start-reload.sh
COPY ./app /app
WORKDIR /app/
ENV PYTHONPATH=/app
EXPOSE 80
# Run the start script, it will check for an /app/prestart.sh script (e.g. for migrations)
# And then will start Gunicorn with Uvicorn
CMD ["/start.sh"]
