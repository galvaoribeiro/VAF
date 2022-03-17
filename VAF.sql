with 

tb_pessoa as (
    select distinct p.co_cnpj_cpf, p.no_razao_social, extract(year from da_referencia) ano, p.co_regime_pagto as regime,
    p.co_cnpj_cpf||extract(year from da_referencia) cnpj_ano
    from bi.dm_regime_pagto_contribuinte p
    where p.da_referencia  between '01/01/2021' and '31/12/2021' -->= '01/01/2017'
    and p.co_cnpj_cpf = '05435147000128'
),

tb_entrada as (

    select b.co_cnpj_cpf, b.ano, b.cnpj_ano, case when b.regime in ('001','016') then
    
         ( --t.co_cnpj_cpf_declarante dest, extract (year from t.da_referencia) ANO, t.co_cnpj_cpf_declarante||extract (year from t.da_referencia) cnpj_ano,
            select nvl(sum(case when (T.CO_CFOP LIKE '1%' OR T.CO_CFOP LIKE'2%' OR T.CO_CFOP LIKE'3%') 
                         and t.co_cfop in (select c.co_cfop from BI.dm_cfop c where c.in_vaf = 'X') then(t.vl_operacao) end),0)        

            
            from BI.FATO_EFD_SUMARIZADA t --, BI.DM_PESSOA p
            --inner join tb_pessoa c on c.co_cnpj_cpf = t.co_cnpj_cpf_declarante
            --where p.co_cnpj_cpf = t.co_cnpj_cpf_declarante        
            where t.da_referencia between '01/01/2021' and '31/12/2021'        
            and t.uf_origem = 'RO'
            --and p.co_regime_pagto in ('001','016')
            --and c.regime in ('001','016') ############################# AO INVÉS DE FAZER O INNER JOIN TESTAR UM SUBSELECT AQUI.
            -------and t.co_cnpj_cpf_declarante in (select co_cnpj_cpf from tb_pessoa b where b.regime in ('001','016'))
            and t.co_cnpj_cpf_declarante = '05435147000128'
            and t.co_cnpj_cpf_declarante||extract (year from t.da_referencia) = b.cnpj_ano
            --group by  extract (year from t.da_referencia), t.co_cnpj_cpf_declarante, t.co_cnpj_cpf_declarante||extract (year from t.da_referencia) 
        
        )  else 
        
                (
        
                    select --nf_s.co_destinatario dest, 
                    --extract(year from nf_s.da_referencia) ano, 
                    --nf_s.co_destinatario||extract(year from nf_s.da_referencia) cnpj_ano,  
                    nvl(sum(nvl(nf_s.prod_vprod+nf_s.prod_vfrete+nf_s.prod_vseg-nf_s.prod_vdesc,0)),0)
                    from bi.fato_nfe_nfce_sumarizada nf_s
                    --inner join tb_pessoa c on c.co_cnpj_cpf = nf_s.co_destinatario
                    left join bi.dm_cfop f on f.co_cfop = nf_s.co_cfop
                    
                    --where nf_s.co_destinatario = c.co_cnpj_cpf
                    where nf_s.da_referencia between '01/01/2021' and '31/12/2021'
                    and nf_s.co_tp_nf = 1 --notas de saída
                    and f.in_vaf = 'X'
                    --and c.regime not in ('001','016')
                    -------and nf_s.co_destinatario in (select co_cnpj_cpf from tb_pessoa b where b.regime not in ('001','016'))
                    and nf_s.co_destinatario = '05435147000128'
                    and nf_s.co_destinatario||extract(year from nf_s.da_referencia) = b.cnpj_ano
                    --group by extract(year from nf_s.da_referencia), nf_s.co_destinatario, nf_s.co_destinatario||extract(year from nf_s.da_referencia)
        
        
        ) end as vprod
    
    from tb_pessoa b
        
      
),

tb_saida as (


    select b.co_cnpj_cpf, b.ano, b.cnpj_ano, case when b.regime in ('001','016') then
    
         ( --t.co_cnpj_cpf_declarante dest, extract (year from t.da_referencia) ANO, t.co_cnpj_cpf_declarante||extract (year from t.da_referencia) cnpj_ano,
            select nvl(sum(case when (T.CO_CFOP LIKE '5%' OR T.CO_CFOP LIKE'6%' OR T.CO_CFOP LIKE'7%') 
                         and t.co_cfop in (select c.co_cfop from BI.dm_cfop c where c.in_vaf = 'X') then(t.vl_operacao) end),0)        

            
            from BI.FATO_EFD_SUMARIZADA t --, BI.DM_PESSOA p
            --inner join tb_pessoa c on c.co_cnpj_cpf = t.co_cnpj_cpf_declarante
            --where p.co_cnpj_cpf = t.co_cnpj_cpf_declarante        
            where t.da_referencia between '01/01/2021' and '31/12/2021'        
            and t.uf_origem = 'RO'
            --and p.co_regime_pagto in ('001','016')
            --and c.regime in ('001','016') ############################# AO INVÉS DE FAZER O INNER JOIN TESTAR UM SUBSELECT AQUI.
            -------and t.co_cnpj_cpf_declarante in (select co_cnpj_cpf from tb_pessoa b where b.regime in ('001','016'))
            and t.co_cnpj_cpf_declarante = '05435147000128'
            and t.co_cnpj_cpf_declarante||extract (year from t.da_referencia) = b.cnpj_ano
            --group by  extract (year from t.da_referencia), t.co_cnpj_cpf_declarante, t.co_cnpj_cpf_declarante||extract (year from t.da_referencia) 
        
        )  else 
        
                (
        
                    select --nf_s.co_destinatario dest, 
                    --extract(year from nf_s.da_referencia) ano, 
                    --nf_s.co_destinatario||extract(year from nf_s.da_referencia) cnpj_ano,  
                    nvl(sum(nvl(nf_s.prod_vprod+nf_s.prod_vfrete+nf_s.prod_vseg-nf_s.prod_vdesc,0)),0)
                    from bi.fato_nfe_nfce_sumarizada nf_s
                    --inner join tb_pessoa c on c.co_cnpj_cpf = nf_s.co_destinatario
                    left join bi.dm_cfop f on f.co_cfop = nf_s.co_cfop
                    
                    --where nf_s.co_destinatario = c.co_cnpj_cpf
                    where nf_s.da_referencia between '01/01/2021' and '31/12/2021'
                    and nf_s.co_tp_nf = 1 --notas de saída
                    and f.in_vaf = 'X'
                    --and c.regime not in ('001','016')
                    -------and nf_s.co_destinatario in (select co_cnpj_cpf from tb_pessoa b where b.regime not in ('001','016'))
                    and nf_s.co_emitente = '05435147000128'
                    and nf_s.co_emitente||extract(year from nf_s.da_referencia) = b.cnpj_ano
                    --group by extract(year from nf_s.da_referencia), nf_s.co_destinatario, nf_s.co_destinatario||extract(year from nf_s.da_referencia)
        
        
        ) end as vprod
    
    from tb_pessoa b



)


--select * from tb_entrada



select distinct 
a.co_cnpj_cpf, 
a.ano, 
nvl(x.vprod,0) entrada, 
nvl(y.vprod,0) saida, 
nvl(y.vprod,0) - nvl(x.vprod,0) vaf 

from tb_pessoa a
left join tb_saida y on a.cnpj_ano = y.cnpj_ano 
left join tb_entrada x on a.cnpj_ano = x.cnpj_ano 

