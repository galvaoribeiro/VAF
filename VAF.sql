with 

tb_pessoa as (
    select distinct p.co_cnpj_cpf, p.no_razao_social, extract(year from da_referencia) ano, p.co_regime_pagto as regime, p.desc_reg_pagto,
    p.co_cnpj_cpf||extract(year from da_referencia) cnpj_ano
    from bi.dm_regime_pagto_contribuinte p
    where p.da_referencia  >= '01/01/2017' -->= '01/01/2017'
    --and p.co_cnpj_cpf = '05435147000128'
),

tb_entrada as (

    select b.co_cnpj_cpf, b.ano, b.cnpj_ano, case when b.regime in ('001','016') then
    
         ( 
            select nvl(sum(case when (T.CO_CFOP LIKE '1%' OR T.CO_CFOP LIKE'2%' OR T.CO_CFOP LIKE'3%') 
                         and t.co_cfop in (select c.co_cfop from BI.dm_cfop c where c.in_vaf = 'X') then(t.vl_operacao) end),0)        

            
            from BI.FATO_EFD_SUMARIZADA t
            where t.da_referencia >= '01/01/2017'        
            and t.uf_origem = 'RO'
            --and t.co_cnpj_cpf_declarante = '05435147000128'
            and t.co_cnpj_cpf_declarante||extract (year from t.da_referencia) = b.cnpj_ano
             
        
        )  else 
        
                (
        
                    select   
                    nvl(sum(nvl(nf_s.prod_vprod+nf_s.prod_vfrete+nf_s.prod_vseg-nf_s.prod_vdesc,0)),0)
                    from bi.fato_nfe_nfce_sumarizada nf_s
                    left join bi.dm_cfop f on f.co_cfop = nf_s.co_cfop
                    where nf_s.da_referencia >= '01/01/2017'
                    and nf_s.co_tp_nf = 1 --notas de saída
                    and f.in_vaf = 'X'
                    --and nf_s.co_destinatario = '05435147000128'
                    and nf_s.co_destinatario||extract(year from nf_s.da_referencia) = b.cnpj_ano
        
        
        ) end as vprod
    
    from tb_pessoa b 
        
      
),

tb_saida as (


    select b.co_cnpj_cpf, b.ano, b.cnpj_ano, case when b.regime in ('001','016') then
    
         (
            select nvl(sum(case when (T.CO_CFOP LIKE '5%' OR T.CO_CFOP LIKE'6%' OR T.CO_CFOP LIKE'7%') 
                         and t.co_cfop in (select c.co_cfop from BI.dm_cfop c where c.in_vaf = 'X') then(t.vl_operacao) end),0)        

            
            from BI.FATO_EFD_SUMARIZADA t  
            where t.da_referencia >= '01/01/2017'        
            and t.uf_origem = 'RO'
            --and t.co_cnpj_cpf_declarante = '05435147000128'
            and t.co_cnpj_cpf_declarante||extract (year from t.da_referencia) = b.cnpj_ano 
        
        )  else 
        
                (
        
                    select 
                    nvl(sum(nvl(nf_s.prod_vprod+nf_s.prod_vfrete+nf_s.prod_vseg-nf_s.prod_vdesc,0)),0)
                    from bi.fato_nfe_nfce_sumarizada nf_s
                    left join bi.dm_cfop f on f.co_cfop = nf_s.co_cfop

                    where nf_s.da_referencia >= '01/01/2017'
                    and nf_s.co_tp_nf = 1 --notas de saída
                    and f.in_vaf = 'X'
                    --and nf_s.co_emitente = '05435147000128'
                    and nf_s.co_emitente||extract(year from nf_s.da_referencia) = b.cnpj_ano
        
        
        ) end as vprod
    
    from tb_pessoa b


),


tab_inv as (

select i.co_cnpj_cpf_declarante, i.da_inventario, extract(year from i.da_inventario) as ano_inv, nvl(i.vl_inv,0) as vl_inv
from BI.fato_efd_inventario i
where extract (month from i.da_inventario) = '12'
      and extract (day from i.da_inventario) = '31'    )



select distinct
a.ano,
a.co_cnpj_cpf,
a.no_razao_social,
a.regime,
a.desc_reg_pagto,
nvl(x.vprod,0) entrada, 
nvl(y.vprod,0) saida,
nvl(z.vl_inv,0) as estoque_incial, 
nvl(y.vl_inv,0) as estoque_final,
nvl(z.vl_inv,0) + nvl(x.vprod,0) - nvl(y.vl_inv,0) "CMV (EI + C - EF)",
nvl(y.vprod,0) - (nvl(z.vl_inv,0) + nvl(x.vprod,0) - nvl(y.vl_inv,0)) as "VAF (SAIDA - CMV)"


from tb_pessoa a
left join tb_saida y on a.cnpj_ano = y.cnpj_ano 
left join tb_entrada x on a.cnpj_ano = x.cnpj_ano

left join tab_inv y on x.co_cnpj_cpf = y.co_cnpj_cpf_declarante and x.ano = y.ano_inv
left join tab_inv z on x.co_cnpj_cpf = z.co_cnpj_cpf_declarante and  x.ano = z.ano_inv+1

order by 1

