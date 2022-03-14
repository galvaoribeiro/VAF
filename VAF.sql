with

tb_pessoa as (
    select distinct p.co_cnpj_cpf, p.no_razao_social, extract(year from da_referencia) ano, 
    p.co_cnpj_cpf||extract(year from da_referencia) cnpj_ano
    from bi.dm_regime_pagto_contribuinte p
    where p.da_referencia between '01/01/2021' and '31/12/2021'
),

tb_entrada as (

        select nf_s.co_destinatario dest, 
        extract(year from nf_s.da_referencia) ano, 
        nf_s.co_destinatario||extract(year from nf_s.da_referencia) cnpj_ano,  
        nvl(sum(nvl(nf_s.prod_vprod+nf_s.prod_vfrete+nf_s.prod_vseg-nf_s.prod_vdesc,0)),0) vprod
        from bi.fato_nfe_nfce_sumarizada nf_s
        left join tb_pessoa c on c.co_cnpj_cpf = nf_s.co_destinatario
        left join bi.dm_cfop f on f.co_cfop = nf_s.co_cfop
        where nf_s.da_referencia between '01/01/2021' and '31/12/2021'
        and nf_s.co_destinatario = c.co_cnpj_cpf
        and nf_s.co_tp_nf = 1 --notas de saída
        and f.in_vaf = 'X'
        group by extract(year from nf_s.da_referencia), nf_s.co_destinatario, nf_s.co_destinatario||extract(year from nf_s.da_referencia)

),

tb_saida as (

        select nf_s.co_emitente, 
        extract(year from nf_s.da_referencia) ano, 
        nf_s.co_emitente||extract(year from nf_s.da_referencia) cnpj_ano,  
        nvl(sum(nvl(nf_s.prod_vprod+nf_s.prod_vfrete+nf_s.prod_vseg-nf_s.prod_vdesc,0)),0) vprod
        from bi.fato_nfe_nfce_sumarizada nf_s
        left join tb_pessoa c on c.co_cnpj_cpf = nf_s.co_emitente
        left join bi.dm_cfop f on f.co_cfop = nf_s.co_cfop
        where nf_s.da_referencia between '01/01/2021' and '31/12/2021'
        and nf_s.co_emitente = c.co_cnpj_cpf
        and nf_s.co_tp_nf = 1 --notas de saída
        and f.in_vaf = 'X'
        group by extract(year from nf_s.da_referencia), nf_s.co_emitente, nf_s.co_emitente||extract(year from nf_s.da_referencia)

)


select distinct 
a.co_cnpj_cpf, 
a.ano, 
nvl(x.vprod,0) entrada, 
nvl(y.vprod,0) saida, 
nvl(y.vprod,0)-nvl(x.vprod,0) vaf 

from tb_pessoa a
left join tb_saida y on a.cnpj_ano = y.cnpj_ano --substr(a.co_cnpj_cpf,1,8) = y.emit and a.ano = y.ano
left join tb_entrada x on a.cnpj_ano = x.cnpj_ano --substr(a.co_cnpj_cpf,1,8) = x.dest and a.ano = x.ano
--where a.co_cnpj_cpf is not null