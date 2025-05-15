# Weapon Customization Pro

**Sistema completo, expansível e modular para customização, upgrades, marketplace, loot e efeitos de armas para MTA!**

## Estrutura

- **server/**: scripts server-side (inventário, armas, loja, lootbox, mercado)
- **client/**: scripts client-side (UI, efeitos, sons)
- **data/**: arquivos JSON de armas, skins, attachments, lootboxes, upgrades
- **img/**: imagens de armas, skins, UI
- **models/**: arquivos DFF/TXD (coloque aqui seus modelos)
- **sounds/**: sons custom
- **meta.xml**: registro do resource

## Recursos

- Customização visual e funcional de armas (skins, efeitos raros, attachments reais)
- Sistema de lootbox com roleta visual e raridades
- Loja e marketplace player-to-player (venda/troca de armas/skins)
- Sistema de upgrades de armas (XP, nível, bônus)
- Inventário modular, fácil expansão
- Suporte a VIP/ACL para itens exclusivos
- Pronto para integração com banco, eventos, economia, etc.

## Como adicionar armas/skins

1. Adicione os arquivos DFF/TXD em models/.
2. Crie PNG para preview em img/weapons/ e img/skins/.
3. Edite os arquivos JSON correspondentes em data/.
4. O sistema carrega tudo automaticamente.

## Como usar

- Use `/customizararma` ou F5 para abrir o painel.
- Navegue entre abas: Inventário, Loja, Caixas, Mercado.
- Customize, equipe, venda, troque, abra lootboxes.
- Nivele suas armas com XP ao usá-las.

## Expansão

- Adicione novas armas/skins/attachments/upgrades apenas editando JSON.
- Crie efeitos visuais com shaders/partículas em weapon_vfx.lua.
- Integre com sistema de economia, missões, eventos facilmente.

## Observações

- Pronto para produção, só faltando adicionar seus assets.
- Scripts ultra-comentados, ideais para equipe grande.
- Para banco de dados, basta trocar a persistência nas funções de inventário.

---