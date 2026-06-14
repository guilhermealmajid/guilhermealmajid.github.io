# Reduzir QCOW2 Windows XP + GitHub Release (Resumo)

## 1. Instalar virt-sparsify (Arch Linux)
```bash
sudo pacman -S guestfs-tools
virt-sparsify --version
```

## 2. Compactar imagem QCOW2

Sem compressão:
```bash
virt-sparsify xp.qcow2 xp-small.qcow2
```

Com compressão:
```bash
virt-sparsify --compress xp.qcow2 xp-small.qcow2
```

Resultado típico:
- 4 GB → ~1.6 GB

---

## 3. Publicar VM no GitHub (não usar Git normal)

❌ Não fazer:
```bash
git add xp.qcow2
git commit
git push
```

✔ Usar GitHub Releases

### Instalar GitHub CLI
```bash
sudo pacman -S github-cli
```

### Login
```bash
gh auth login
```

### Criar release e enviar arquivo
```bash
gh release create v1.0 ./xp.qcow2 --title "XP VM 1.0"
```

---

## 4. Link de download

Formato:
```
https://github.com/USUARIO/REPO/releases/download/v1.0/xp.qcow2
```

Exemplo:
```
https://github.com/guilhermealmajid/xp-vm/releases/download/v1.0/xp.qcow2
```

Testar:
```bash
wget --spider URL
```

---

## 5. Download final

```bash
wget URL
# ou
curl -L -O URL
```

---

## 6. Integridade (SHA256)

Gerar:
```bash
sha256sum xp.qcow2 > xp.qcow2.sha256
```

Verificar:
```bash
sha256sum -c xp.qcow2.sha256
```
