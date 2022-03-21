--10 minutos

with 

tb_pessoa as (
    select distinct p.co_cnpj_cpf cnpj, p.no_razao_social, extract(year from da_referencia) ano, 
    p.co_regime_pagto as regime, p.desc_reg_pagto,
    p.co_cnpj_cpf||extract(year from da_referencia) cnpj_ano
    from bi.dm_regime_pagto_contribuinte p
    where p.da_referencia  >= '01/01/2017' 
    --and p.co_cnpj_cpf = '08398411000199'
),

tb_efd as (

select t.co_cnpj_cpf_declarante||extract (year from t.da_referencia) cnpj_ano,
extract (year from t.da_referencia) as ANO, t.co_cnpj_cpf_declarante cnpj,
       nvl(sum(case when (T.CO_CFOP LIKE '1%' OR T.CO_CFOP LIKE'2%' OR T.CO_CFOP LIKE'3%') 
                         and t.co_cfop in (select c.co_cfop from BI.dm_cfop c where c.in_vaf = 'X') then(t.vl_operacao) end),0) entrada,
                         
       nvl(sum(case when (T.CO_CFOP LIKE '5%' OR T.CO_CFOP LIKE'6%' OR T.CO_CFOP LIKE'7%') 
                         and t.co_cfop in (select c.co_cfop from BI.dm_cfop c where c.in_vaf = 'X') then(t.vl_operacao) end),0) saida       

            from BI.FATO_EFD_SUMARIZADA t
            left join tb_pessoa p on p.cnpj_ano = t.co_cnpj_cpf_declarante||extract (year from t.da_referencia)
            where t.da_referencia >= '01/01/2017'
            and t.uf_origem = 'RO'
            and p.regime in ('001','016')
            --and t.co_cnpj_cpf_declarante= '08398411000199'
            
       group by t.co_cnpj_cpf_declarante||extract (year from t.da_referencia), extract (year from t.da_referencia), t.co_cnpj_cpf_declarante

),
     
      
tb_entrada_nf as (

        select
        nf_s.co_destinatario||extract(year from nf_s.da_referencia) cnpj_ano,
        extract(year from nf_s.da_referencia) ano,
        nf_s.co_destinatario as cnpj,
        nvl(sum(nvl(nf_s.prod_vprod+nf_s.prod_vfrete+nf_s.prod_vseg-nf_s.prod_vdesc,0)),0) entrada
        from bi.fato_nfe_nfce_sumarizada nf_s
        left join tb_pessoa p on p.cnpj_ano = nf_s.co_destinatario||extract(year from nf_s.da_referencia)
        left join bi.dm_cfop f on f.co_cfop = nf_s.co_cfop
        where nf_s.da_referencia >= '01/01/2017'
        and p.regime not in ('001','016')
        and nf_s.co_tp_nf = 1 --notas de saída
        and f.in_vaf = 'X'
        --and nf_s.co_destinatario = '08398411000199'
        group by 
        nf_s.co_destinatario||extract(year from nf_s.da_referencia),
        extract(year from nf_s.da_referencia),
        nf_s.co_destinatario

),


tb_saida_nf as (

        select
        nf_s.co_emitente||extract(year from nf_s.da_referencia) cnpj_ano,
        extract(year from nf_s.da_referencia) ano,
        nf_s.co_emitente as cnpj,
        nvl(sum(nvl(nf_s.prod_vprod+nf_s.prod_vfrete+nf_s.prod_vseg-nf_s.prod_vdesc,0)),0) saida
        from bi.fato_nfe_nfce_sumarizada nf_s
        left join tb_pessoa p on p.cnpj_ano = nf_s.co_emitente||extract(year from nf_s.da_referencia)
        left join bi.dm_cfop f on f.co_cfop = nf_s.co_cfop
        where nf_s.da_referencia >= '01/01/2017'
        and p.regime not in ('001','016')
        and nf_s.co_tp_nf = 1 --notas de saída
        and f.in_vaf = 'X'
        --and nf_s.co_emitente = '08398411000199'
        group by 
        nf_s.co_emitente||extract(year from nf_s.da_referencia),
        extract(year from nf_s.da_referencia),
        nf_s.co_emitente

),

tb_entrada as (

select cnpj_ano, cnpj, ano, entrada as vprod, case when tb_efd.cnpj is not null then 'EFD' end as origem from tb_efd
union all
select cnpj_ano, cnpj, ano, entrada, case when tb_entrada_nf.cnpj is not null then 'NF' end as origem from tb_entrada_nf


),

tb_saida as (

select cnpj_ano, cnpj, ano, saida as vprod, case when tb_efd.cnpj is not null then 'EFD' end as origem from tb_efd
union all
select cnpj_ano, cnpj, ano, saida, case when tb_saida_nf.cnpj is not null then 'NF' end as origem from tb_saida_nf


),


tab_inv as (

select 
i.co_cnpj_cpf_declarante||extract(year from i.da_inventario) cnpj_ano,
i.da_inventario, 
extract(year from i.da_inventario) as ano_inv, 
nvl(i.vl_inv,0) as vl_inv
from BI.fato_efd_inventario i
where extract (month from i.da_inventario) = '12'
      and extract (day from i.da_inventario) = '31'
      --and i.co_cnpj_cpf_declarante = '08398411000199'
      )


select distinct
a.ano,
a.cnpj,
a.no_razao_social,
l.co_municipio,
l.no_municipio,
a.regime,
a.desc_reg_pagto,
nvl(x.vprod,0) entrada, 
nvl(y.vprod,0) saida,
nvl(z.vl_inv,0) as estoque_incial, 
nvl(w.vl_inv,0) as estoque_final,
nvl(z.vl_inv,0) + nvl(x.vprod,0) - nvl(w.vl_inv,0) "CMV (EI + C - EF)",
nvl(y.vprod,0) - (nvl(z.vl_inv,0) + nvl(x.vprod,0) - nvl(w.vl_inv,0)) as "VAF (SAIDA - CMV)",
a.cnpj_ano,
x.origem as origem_entrada,
y.origem as origem_saida


from tb_pessoa a
left join tb_entrada x on a.cnpj_ano = x.cnpj_ano
left join tb_saida y on a.cnpj_ano = y.cnpj_ano 

left join tab_inv w on a.cnpj_ano = w.cnpj_ano 
left join tab_inv z on a.cnpj_ano = z.cnpj_ano + 1

left join bi.dm_pessoa d on d.co_cnpj_cpf = a.cnpj
    left join bi.dm_localidade l on l.co_municipio = d.co_municipio

--order by 2,1

