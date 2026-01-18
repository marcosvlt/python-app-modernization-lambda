import csv
import json
import argparse
from typing import Dict, List, Set
from datetime import datetime


def clean_data(caminho_csv: str) -> List[Dict[str, str]]:
    """
    Processa e limpa dados de CSV FIPE, removendo duplicatas, 
    corrigindo erros e reformatando dados.
    
    Returns:
        Lista de dicionários com dados limpos e validados
    """
    registros_limpos: List[Dict[str, str]] = []
    registros_unicos: Set[tuple] = set()
    
    with open(caminho_csv, "r", encoding="utf-8", newline="") as f:
        leitor = csv.DictReader(f)
        
        if leitor.fieldnames is None:
            raise ValueError("CSV sem cabeçalho ou vazio.")
        
        for linha in leitor:
            try:
                # Extrai e limpa campos
                codigo_fipe = linha.get("codigoFipe", "").strip()
                marca = linha.get("marca", "").strip()
                modelo = linha.get("modelo", "").strip()
                ano_modelo = linha.get("anoModelo", "").strip()
                mes_referencia = linha.get("mesReferencia", "").strip()
                ano_referencia = linha.get("anoReferencia", "").strip()
                valor = linha.get("valor", "").strip()
                
                # Valida campos obrigatórios
                if not all([codigo_fipe, marca, modelo, ano_modelo, valor]):
                    continue
                
                # Valida e normaliza ano do modelo
                try:
                    ano_int = int(ano_modelo)
                    if ano_int < 1900 or ano_int > datetime.now().year + 1:
                        continue  # Ano inválido
                    ano_modelo = str(ano_int)
                except ValueError:
                    continue
                
                # Valida e normaliza ano de referência
                if ano_referencia:
                    try:
                        ano_ref_int = int(ano_referencia)
                        if ano_ref_int < 2000 or ano_ref_int > datetime.now().year:
                            ano_referencia = ""
                        else:
                            ano_referencia = str(ano_ref_int)
                    except ValueError:
                        ano_referencia = ""
                
                # Normaliza valor (remove espaços, converte vírgula em ponto)
                valor_normalizado = (
                    valor.replace(" ", "")
                    .replace("\u00A0", "")
                    .replace(",", ".")
                )
                
                # Valida valor numérico
                try:
                    valor_float = float(valor_normalizado)
                    if valor_float <= 0:
                        continue  # Valores negativos ou zero são inválidos
                    valor_normalizado = f"{valor_float:.2f}"
                except ValueError:
                    continue
                
                # Normaliza marca e modelo (capitalização)
                marca = marca.upper()
                modelo = " ".join(modelo.split())  # Remove espaços extras
                
                # Cria chave única para detectar duplicatas
                chave_unica = (
                    codigo_fipe,
                    marca,
                    modelo,
                    ano_modelo,
                    mes_referencia,
                    ano_referencia,
                )
                
                # Remove duplicatas
                if chave_unica in registros_unicos:
                    continue
                
                registros_unicos.add(chave_unica)
                
                # Adiciona registro limpo
                registro_limpo = {
                    "codigoFipe": codigo_fipe,
                    "marca": marca,
                    "modelo": modelo,
                    "anoModelo": ano_modelo,
                    "mesReferencia": mes_referencia,
                    "anoReferencia": ano_referencia,
                    "valor": valor_normalizado,
                }
                
                registros_limpos.append(registro_limpo)
                
            except Exception:
                # Ignora linhas com erros inesperados
                continue
    
    # Ordena registros por ano, marca e modelo para consistência
    registros_limpos.sort(
        key=lambda x: (x["anoModelo"], x["marca"], x["modelo"])
    )
    
    return registros_limpos


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Processa e limpa um CSV da tabela FIPE histórica, removendo duplicatas, "
            "corrigindo erros e reformatando dados."
        )
    )
    parser.add_argument(
        "--input",
        "-i",
        default="tabela-fipe-historico-precos.csv",
        help="Caminho do arquivo CSV de entrada (padrão: tabela-fipe-historico-precos.csv)",
    )
    parser.add_argument(
        "--output",
        "-o",
        default="dados_limpos.json",
        help="Caminho do arquivo JSON de saída (padrão: dados_limpos.json)",
    )

    args = parser.parse_args()

    dados_limpos = calcular_medias_por_ano_e_marca(args.input)

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(dados_limpos, f, ensure_ascii=False, indent=2)

    print(f"Processamento concluído!")
    print(f"  Total de registros limpos: {len(dados_limpos)}")
    print(f"  Arquivo JSON gerado em: {args.output}")


if __name__ == "__main__":
    main()


