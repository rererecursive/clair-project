# clair CfHighlander project
---

## Cfhighlander Setup

install cfhighlander [gem](https://github.com/theonestack/cfhighlander)

```bash
gem install cfhighlander
```

or via docker

```bash
docker pull theonestack/cfhighlander
```

compiling the templates

```bash
cfcompile clair
```

compiling with the vaildate fag to validate the templates

```bash
cfcompile clair --validate
```

publish the templates to s3

```bash
cfpublish clair --version latest
```
