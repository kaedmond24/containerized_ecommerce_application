FROM python:3.9
RUN git clone https://github.com/kaedmond24/containerized_ecommerce_application.git
WORKDIR containerized_ecommerce_application/backend
RUN pip install -r requirements.txt
EXPOSE 8000
RUN python manage.py migrate
CMD python manage.py runserver 0.0.0.0:8000