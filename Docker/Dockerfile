FROM public.ecr.aws/lambda/python:3.11

# Copia os arquivos da aplicação
COPY src/ ${LAMBDA_TASK_ROOT}/

# (Opcional) Instalar dependências (nenhuma no código fornecido)
# RUN pip install -r requirements.txt

# Define o handler: chamaremos um wrapper lambda_function.py
CMD ["lambda_function.lambda_handler"]
# --- IGNORE ---
#Teste docker edited 4