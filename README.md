Repositories Linux
==================

This project generates the repositories for the linux archives `.deb` and `.rpm`.

The instructions are available at https://repo.vscodium.dev.

Your own repositories
---------------------

This project can be forked and reconfigured to generate repositories from any packages available on GitHub.

### Environment Variables

- `GH_REPOSITORIES` (`VSCodium/vscodium VSCodium/vscodium-insiders`)
- `PACKAGE_NAME` (`codium`)
- `PAGE_NAME` (`vscodium-repo`)
- `PROJECT_NAME` (`VSCodium`)
- `PROJECT_URL` (`https://github.com/VSCodium/vscodium`)
- `R2_BUCKET_NAME` (`vscodium-repo`)
- `R2_BUCKET_URL` (`https://r2repo.vscodium.dev`)
- `REPO_ARCH_DEB` (`amd64 arm64 armhf`)
- `REPO_ARCH_RPM` (`x86_64 aarch64 armv7hl`)
- `REPO_NAME` (`vscodium`)
- `REPO_URL` (`https://repo.vscodium.dev`)

### Secrets Variables

- `secrets.CLOUDFLARE_ACCOUNT_ID`
- `secrets.CLOUDFLARE_API_TOKEN`
- `secrets.CLOUDFLARE_KV_NAMESPACE_ID`
- `secrets.GPG_PASSPHRASE`
- `secrets.GPG_PRIVATE_KEY`

### Debug

#### DNF

```bash
dnf repoquery --location <package name>
```

### Dispatch

Use the following code to create a repository dispatch event to deploy your repositories

```
deploy-repo:
  runs-on: ubuntu-latest
  steps:
    - name: Trigger repository rebuild
      uses: peter-evans/repository-dispatch@v3
      with:
        token: ${{ secrets.STRONGER_GITHUB_TOKEN }}
        repository: VSCodium/repositories-linux
        event-type: deploy
```

Thanks
------

I would like to thank the following projects which have inspired this project:
- https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo
- https://github.com/terminate-notice/terminate-notice.github.io

License
-------

[MIT](http://www.opensource.org/licenses/mit-license.php) &copy; Baptiste Augrain
