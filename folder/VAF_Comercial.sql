-- 47 segundos 

with
tab_efd as (
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


order by 7 
) ,

tab_inv as (

select i.co_cnpj_cpf_declarante, i.da_inventario, extract(year from i.da_inventario) as ano_inv, nvl(i.vl_inv,0) as vl_inv
from BI.fato_efd_inventario i
where extract (month from i.da_inventario) = '12'
      and extract (day from i.da_inventario) = '31'    )

select x.*,  
nvl(z.vl_inv,0) as estoque_incial, nvl(y.vl_inv,0) as estoque_final,
nvl(z.vl_inv,0) + x.entrada - nvl(y.vl_inv,0) cmv,
(x.saída - X.entrada) VAF_legal,
x.saída - (nvl(z.vl_inv,0) + x.entrada - nvl(y.vl_inv,0)) as VAF_Comercial,
case when x.saída = 0 and (nvl(z.vl_inv,0) + x.entrada - nvl(y.vl_inv,0)) = 0 then 0 --saída 0 e cmv 0 %vaf = 0
     when x.saída <> 0 and (nvl(z.vl_inv,0) + x.entrada - nvl(y.vl_inv,0)) = 0 then 1 --saída <>0 e cmv 0 %vaf = 1
 else (
    ( 
        x.saída - (nvl(z.vl_inv,0) + x.entrada - nvl(y.vl_inv,0)) ) / (nvl(z.vl_inv,0) + x.entrada - nvl(y.vl_inv,0))
          
           ) end as PERCENTUAL_VAF

from tab_efd x
left join tab_inv y on x.co_cnpj_cpf_declarante = y.co_cnpj_cpf_declarante and x.ano = y.ano_inv
left join tab_inv z on x.co_cnpj_cpf_declarante = z.co_cnpj_cpf_declarante and  x.ano = z.ano_inv+1