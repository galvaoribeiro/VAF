-- 322 segundos
with
tab_efd as ( -- FAZ O CÁLCULO DO VAF PARA TODAS AS EMPRESAS ESPECIFICADAS
select extract (year from t.da_referencia) as ANO, t.co_cnpj_cpf_declarante, p.ie, p.no_razao_social, l.no_municipio, 
cnae.co_categoria,
case when cnae.co_subsetor = '31' and upper(cnae.no_cnae) like '%ATACAD%' then 'COMÉRCIO ATACADISTA'
       when cnae.co_subsetor = '31' and upper(cnae.no_cnae) like '%VAREJ%' then 'COMÉRCIO VAREJISTA'
       when cnae.co_subsetor <> '31' then cnae.no_subsetor end cnae_subsetor,


nvl(sum(case when (T.CO_CFOP LIKE '1%' OR T.CO_CFOP LIKE'2%' OR T.CO_CFOP LIKE'3%') 
             and t.co_cfop in (select c.co_cfop from BI.dm_cfop c where c.in_vaf = 'X') then(t.vl_operacao) end),0) as ENTRADA,

nvl(sum(case when (T.CO_CFOP LIKE '5%' OR T.CO_CFOP LIKE'6%' OR T.CO_CFOP LIKE'7%') 
             and t.co_cfop in (select c.co_cfop from BI.dm_cfop c where c.in_vaf = 'X')then(t.vl_operacao) end),0) as SAÍDA

from BI.FATO_EFD_SUMARIZADA t, BI.DM_PESSOA p
left join bi.dm_cnae cnae on cnae.co_cnae = p.co_cnae
left join bi.dm_localidade l on l.co_municipio = p.co_municipio
--left join BI.fato_efd_inventario i on i.co_cnpj_cpf_declarante = p.co_cnpj_cpf
where p.co_cnpj_cpf = t.co_cnpj_cpf_declarante
--and p.co_cnpj_cpf = '33337122018921'
and extract (year from t.da_referencia) = '&ANO'
--and extract (month from i.da_inventario) = '12'
--and extract (day from i.da_inventario) = '31'
--and extract (year from i.da_inventario) = '&ANO'
and t.uf_origem = 'RO'
and p.co_regime_pagto in ('001','016')
--and p.co_municipio = '110010'
group by  extract (year from t.da_referencia), t.co_cnpj_cpf_declarante, p.ie, p.no_razao_social, p.co_regime_pagto, l.no_municipio,
cnae.co_categoria,
case when cnae.co_subsetor = '31' and upper(cnae.no_cnae) like '%ATACAD%' then 'COMÉRCIO ATACADISTA'
       when cnae.co_subsetor = '31' and upper(cnae.no_cnae) like '%VAREJ%' then 'COMÉRCIO VAREJISTA'
       when cnae.co_subsetor <> '31' then cnae.no_subsetor end


--order by 7 
) ,

tab_inv as ( -- ARMAZENA OS DADOS DO INVENTÁRIO NO FINAL DO EXERCÍCIO

select i.co_cnpj_cpf_declarante, i.da_inventario, extract(year from i.da_inventario) as ano_inv, nvl(i.vl_inv,0) as vl_inv
from BI.fato_efd_inventario i
where extract (month from i.da_inventario) = '12'
      and extract (day from i.da_inventario) = '31'    ),
      
      
----------------- AS TABELAS A SEGUIR SÃO UTILIZADAS PARA FAZER A MALHA DAS EMPRESAS A SEREM EXCLUÍDAS/INCLUÍDAS ---------------------- 


TAB_ARZ as ( -- ARMAZENA AS EMPRESAS QUE EFETUARAM REMESSAS DE MERCADORIAS DEPOSITADAS EM ARMAZEM OU DEPÓSITO

select
t.co_emitente,
sum(t.prod_vprod) as cfopsum
from bi.fato_nfe_nfce_sumarizada t where t.da_referencia between '01/01/2021' and '31/12/2021'
and  t.co_cfop in ('5906','5907')
group by
t.co_emitente
      ),
      
TAB_CT as ( -- ARMAZENAS AS EMPREAS QUE EFETUARAM TRANSFERÊNCIAS DE MERCADORIAS ENTRE FILIAIS

select
t.co_emitente,
sum(t.prod_vprod) as cfopsum
from bi.fato_nfe_nfce_sumarizada t where t.da_referencia between '01/01/2021' and '31/12/2021'
and  t.co_cfop in ('5152','5409')
group by
t.co_emitente
      ),
      
TAB_5102 AS ( -- ARMAZENA AS EMPRESAS QUE EMITIRAM NFe COM OS CFOP's 5102, 6102 e 7102

select
t.co_emitente,
sum(t.prod_vprod) as cfopsum
from bi.fato_nfe_nfce_sumarizada t where t.da_referencia between '01/01/2021' and '31/12/2021'
and  t.co_cfop in ('5102','6102','7102')
group by
t.co_emitente


),
      
tab_total as ( -- SOMA O TOTAL DE MERCADORIAS SAÍDAS POR EMPRESA
select
t.co_emitente,
sum(t.prod_vprod) as totalsum
from bi.fato_nfe_nfce_sumarizada t where t.da_referencia between '01/01/2021' and '31/12/2021'
and t.co_cfop between '5000' and '7949' 
group by
t.co_emitente
      
      ),
      
tab_result_ARZ as ( -- UTILIZADA PARA ENCONTRAR O PERCENTUAL
select tab_total.co_emitente, p.co_cad_icms, p.co_regime_pagto, p.no_razao_social, TAB_ARZ.cfopsum, tab_total.totalsum, TAB_ARZ.cfopsum/tab_total.totalsum as PERCENTUAL
from TAB_ARZ inner join tab_total on TAB_ARZ.co_emitente = tab_total.co_emitente
inner join bi.dm_pessoa p on p.co_cnpj_cpf = TAB_ARZ.co_emitente       
                  ),
                  
                  
tab_result_CT as ( -- UTILIZADA PARA ENCONTRAR O PERCENTUAL
select tab_total.co_emitente, p.co_cad_icms, p.co_regime_pagto, p.no_razao_social, TAB_CT.cfopsum, tab_total.totalsum, TAB_CT.cfopsum/tab_total.totalsum as PERCENTUAL
from TAB_CT inner join tab_total on TAB_CT.co_emitente = tab_total.co_emitente
inner join bi.dm_pessoa p on p.co_cnpj_cpf = TAB_CT.co_emitente
      ) ,
      
      
TAB_RESULT_5102 as ( -- UTILIZADA PARA INCLUIR AS EMPRESAS QUE NÃO SÃO DO CNAE 'G' MAS QUE EMITIRAM NF NOS CFOP's 5102, 6102 E 7102)
      
select 
tab_total.co_emitente, p.co_cad_icms, p.co_regime_pagto, p.no_razao_social, TAB_5102.cfopsum, tab_total.totalsum, 
TAB_5102.cfopsum/tab_total.totalsum as PERCENTUAL, c.no_categoria, C.CO_CATEGORIA
from TAB_5102 inner join tab_total on TAB_5102.co_emitente = tab_total.co_emitente
inner join bi.dm_pessoa p on p.co_cnpj_cpf = TAB_5102.co_emitente
left join bi.dm_cnae c on p.co_cnae = c.co_cnae where c.co_categoria not in ('G') and p.co_regime_pagto <> '011'

                  ),
      
      
TAB_ZERO AS ( -- ARMAZENA AS EMPRESAS QUE NÃO EFETIVARAM A COMPRA DE MERCADORIAS NO PERÍODO AVALIADO

select distinct p.co_cnpj_cpf, p.co_cad_icms, p.no_razao_social, p.co_regime_pagto from bi.dm_pessoa p
inner join bi.dm_cnae c on c.co_cnae = p.co_cnae 
where not exists (

select distinct t.co_destinatario from bi.fato_nfe_detalhe t where t.co_destinatario = p.co_cnpj_cpf and t.dhemi between '01/01/2019' and '31/12/2019' 
and t.co_cfop in ('5101','5102','5103','5104','5105','5106','5107','5108','5109','5110','5111','5112','5113','5114','5115','5116','5117','5118',
                  '5119','5120','5123','5401','5402','5403','5404','5405',
                  '6101','6102','6103','6104','6105','6106','6107','6108','6109','6110','6111','6112','6113','6114','6115','6116','6117','6118',
                  '6119','6120','6123','6401','6402','6403','6404','6405',
                  '7101','7102','7103','7104','7105','7106','7107','7108','7109','7110','7111','7112','7113','7114','7115','7116','7117','7118',
                  '7119','7120','7123','7401','7402','7403','7404','7405')

       )

)
                  
                  
-----------------------------------------------------------------------------------------
---SELECT FINAL
-----------------------------------------------------------------------------------------

select x.*,  
nvl(z.vl_inv,0) as estoque_incial, nvl(y.vl_inv,0) as estoque_final,
x.saída - (nvl(z.vl_inv,0) + x.entrada - nvl(y.vl_inv,0)) as VAF_Comercial
from tab_efd x
left join tab_inv y on x.co_cnpj_cpf_declarante = y.co_cnpj_cpf_declarante and x.ano = y.ano_inv
left join tab_inv z on x.co_cnpj_cpf_declarante = z.co_cnpj_cpf_declarante and  x.ano = z.ano_inv+1
LEFT JOIN tab_result_ARZ arz on arz.co_emitente = x.co_cnpj_cpf_declarante
LEFT JOIN tab_result_CT ct on ct.co_emitente = x.co_cnpj_cpf_declarante
LEFT JOIN tab_result_5102 gg on gg.co_emitente = x.co_cnpj_cpf_declarante

WHERE
(arz.percentual < 0.8 or arz.percentual is null) -- filtra as empresas que não são do tipo armazém/depósito
AND (ct.percentual < 0.8 or ct.percentual is null) -- filtra as empresas que não são do tipo Centros de Transferência
AND x.co_cnpj_cpf_declarante not in (select zr.co_cnpj_cpf from tab_zero zr) -- filtra as empresas 'compra zero no ano'
AND (x.co_categoria = 'G' or (x.co_categoria <> 'G' and gg.PERCENTUAL >= 0.6 and gg.totalsum > 10000) ) -- exclui as empresas que não são do CNAE 'G', com exceção daquelas cujo somatório de NF for maior que 10.000 e 60% das vendas sejam nos CFOP's 5102, 6102 e 7102.
