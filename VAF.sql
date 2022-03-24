--12 minutos

with 

tb_pessoa as (
    select distinct p.co_cnpj_cpf cnpj, p.no_razao_social,
    p.co_cnpj_cpf||p.da_referencia||p.co_regime_pagto cnpj_mes_regime,
    p.co_cnpj_cpf||extract(year from da_referencia) cnpj_ano, 
    p.da_referencia,
    max(p.co_regime_pagto) keep (dense_rank last order by p.da_referencia) over (partition by p.co_cnpj_cpf||extract(year from da_referencia)) as regime_final,
    p.co_regime_pagto as regime, p.desc_reg_pagto,
    p.co_cnpj_cpf||p.da_referencia cnpj_mes
    from bi.dm_regime_pagto_contribuinte p
    where  p.da_referencia  > = (select trunc(add_months(sysdate,-60),'yyyy') from dual)
    and p.co_cnpj_cpf is not null
    --and p.co_cnpj_cpf in ('30741760000110', '31470234000126')
),

tb_efd as (

select t.co_cnpj_cpf_declarante||p.da_referencia||p.regime cnpj_mes_regime, p.da_referencia mes, p.regime,
--extract (year from t.da_referencia) as ANO, 
t.co_cnpj_cpf_declarante cnpj,
       nvl(sum(case when (T.CO_CFOP LIKE '1%' OR T.CO_CFOP LIKE'2%' OR T.CO_CFOP LIKE'3%') 
                         and t.co_cfop in (select c.co_cfop from BI.dm_cfop c where c.in_vaf = 'X') then(t.vl_operacao) end),0) entrada,
                         
       nvl(sum(case when (T.CO_CFOP LIKE '5%' OR T.CO_CFOP LIKE'6%' OR T.CO_CFOP LIKE'7%') 
                         and t.co_cfop in (select c.co_cfop from BI.dm_cfop c where c.in_vaf = 'X') then(t.vl_operacao) end),0) saida       

            from BI.FATO_EFD_SUMARIZADA t
            left join tb_pessoa p on p.cnpj_mes = t.co_cnpj_cpf_declarante||t.da_referencia
            where  t.da_referencia > = (select trunc(add_months(sysdate,-60),'yyyy') from dual)
            and t.uf_origem = 'RO'
            and p.regime in ('001','016')
            --and t.co_cnpj_cpf_declarante in ('30741760000110', '31470234000126')
            
       group by t.co_cnpj_cpf_declarante||p.da_referencia||p.regime,  p.da_referencia, p.regime,
       t.co_cnpj_cpf_declarante

),
     
     
      
tb_entrada_nf as (

        select
        nf_s.co_destinatario||p.da_referencia||p.regime cnpj_mes_regime, p.da_referencia mes, p.regime,
        --extract(year from nf_s.da_referencia) ano,
        nf_s.co_destinatario as cnpj,
        nvl(sum(nvl(nf_s.prod_vprod+nf_s.prod_vfrete+nf_s.prod_vseg-nf_s.prod_vdesc,0)),0) entrada
        from bi.fato_nfe_nfce_sumarizada nf_s
        left join tb_pessoa p on p.cnpj_mes = nf_s.co_destinatario||nf_s.da_referencia
        left join bi.dm_cfop f on f.co_cfop = nf_s.co_cfop
        where nf_s.da_referencia > = (select trunc(add_months(sysdate,-60),'yyyy') from dual)
        and p.regime not in ('001','016')
        and nf_s.co_tp_nf = 1 --notas de saída
        and f.in_vaf = 'X'
        --and nf_s.co_destinatario in ('30741760000110', '31470234000126')
        group by 
         nf_s.co_destinatario||p.da_referencia||p.regime,
         nf_s.co_destinatario , p.da_referencia, p.regime

),




tb_saida_nf as (

        select
        nf_s.co_emitente||p.da_referencia||p.regime cnpj_mes_regime, p.da_referencia mes, p.regime,
        --extract(year from nf_s.da_referencia) ano,
        nf_s.co_emitente as cnpj,
        nvl(sum(nvl(nf_s.prod_vprod+nf_s.prod_vfrete+nf_s.prod_vseg-nf_s.prod_vdesc,0)),0) saida
        from bi.fato_nfe_nfce_sumarizada nf_s
        left join tb_pessoa p on p.cnpj_mes = nf_s.co_emitente||nf_s.da_referencia
        left join bi.dm_cfop f on f.co_cfop = nf_s.co_cfop
        where nf_s.da_referencia > = (select trunc(add_months(sysdate,-60),'yyyy') from dual)
        and p.regime not in ('001','016')
        and nf_s.co_tp_nf = 1 --notas de saída
        and f.in_vaf = 'X'
        --and nf_s.co_emitente in ('30741760000110', '31470234000126')
        group by 
        nf_s.co_emitente||p.da_referencia||p.regime,
        nf_s.co_emitente , p.da_referencia, p.regime

),



tb_entrada as (

select cnpj_mes_regime, cnpj, mes, entrada as vprod from tb_efd
union all
select cnpj_mes_regime, cnpj, mes, entrada from tb_entrada_nf


),


tb_saida as (

select cnpj_mes_regime, cnpj, mes, saida as vprod from tb_efd
union all
select cnpj_mes_regime, cnpj, mes, saida from tb_saida_nf


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
      --and i.co_cnpj_cpf_declarante in ('30741760000110', '31470234000126')
      )


select distinct
extract(year from a.da_referencia) ano,
a.cnpj,
a.no_razao_social,
l.co_municipio,
l.no_municipio,
a.regime_final,
--a.desc_reg_pagto,
nvl(sum(x.vprod),0) entrada, 
nvl(sum(y.vprod),0) saida,
nvl(z.vl_inv,0) as estoque_incial, 
nvl(w.vl_inv,0) as estoque_final,
nvl(z.vl_inv,0) + nvl(sum(x.vprod),0) - nvl(w.vl_inv,0) "CMV (EI + C - EF)",
nvl(sum(y.vprod),0) - (nvl(z.vl_inv,0) + nvl(sum(x.vprod),0) - nvl(w.vl_inv,0)) as "VAF (SAIDA - CMV)"



from tb_pessoa a
left join tb_entrada x on a.cnpj_mes_regime = x.cnpj_mes_regime
left join tb_saida y on a.cnpj_mes_regime = y.cnpj_mes_regime 

left join tab_inv w on a.cnpj_ano = w.cnpj_ano 
left join tab_inv z on a.cnpj_ano = z.cnpj_ano + 1

left join bi.dm_pessoa d on d.co_cnpj_cpf = a.cnpj
    left join bi.dm_localidade l on l.co_municipio = d.co_municipio
    
    
group by
extract(year from a.da_referencia),

a.cnpj,
a.no_razao_social,
l.co_municipio,
l.no_municipio,
nvl(z.vl_inv,0), 
nvl(w.vl_inv,0),
a.regime_final


