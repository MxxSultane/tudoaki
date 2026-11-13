# Diagnósticos do renderer anterior — 4C.3D

Base 49e1724319988ef66890f5742de8eea84692c112. A suite de 292 passou; a matriz de renderização adicional teve 26 falhas em 164 casos. Quatro casos de valores longos a 200% não produziram PNG válido. Os outros 22 produziram PNG com erro visual e falharam a verificação de ausência de excepções. Nenhuma imagem foi fabricada para preencher estas lacunas.

Erros observados: RenderFlex overflowed by 13 pixels on the right; ListTile trailing widget consumes the entire tile width; encadeamento de RenderBox was not laid out. Os logs extensos foram mantidos na execução local; abaixo está o inventário exacto dos casos.

| Caso anterior que falhou | PNG disponível |
| --- | --- |
| finance-empty-320-200-light | Sim — overflow/excepção visível |
| finance-filled-320-200-light | Sim — overflow/excepção visível |
| finance-currency-320-200-light | Sim — overflow/excepção visível |
| finance-month-empty-320-200-light | Sim — overflow/excepção visível |
| finance-long-320-200-light | Não — falha de layout |
| finance-long-360-200-light | Não — falha de layout |
| finance-register-320-200-light | Sim — overflow/excepção visível |
| finance-edit-320-200-light | Sim — overflow/excepção visível |
| finance-error-320-200-light | Sim — overflow/excepção visível |
| finance-budget-320-200-light | Sim — overflow/excepção visível |
| finance-saving-320-200-light | Sim — overflow/excepção visível |
| finance-recurring-320-200-light | Sim — overflow/excepção visível |
| finance-confirm-320-200-light | Sim — overflow/excepção visível |
| finance-empty-320-200-dark | Sim — overflow/excepção visível |
| finance-filled-320-200-dark | Sim — overflow/excepção visível |
| finance-currency-320-200-dark | Sim — overflow/excepção visível |
| finance-month-empty-320-200-dark | Sim — overflow/excepção visível |
| finance-long-320-200-dark | Não — falha de layout |
| finance-long-360-200-dark | Não — falha de layout |
| finance-register-320-200-dark | Sim — overflow/excepção visível |
| finance-edit-320-200-dark | Sim — overflow/excepção visível |
| finance-error-320-200-dark | Sim — overflow/excepção visível |
| finance-budget-320-200-dark | Sim — overflow/excepção visível |
| finance-saving-320-200-dark | Sim — overflow/excepção visível |
| finance-recurring-320-200-dark | Sim — overflow/excepção visível |
| finance-confirm-320-200-dark | Sim — overflow/excepção visível |
