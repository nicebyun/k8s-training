Extras
=====================

These extra items should help us navigate lab faster.

1. [Kube context switch](https://github.com/ahmetb/kubectx)
    ```shell
    git clone https://github.com/ahmetb/kubectx.git ~/.kubectx
    COMPDIR=$(pkg-config --variable=completionsdir bash-completion)
    sudo ln -sf ~/.kubectx/completion/kubens.bash $COMPDIR/kubens
    sudo ln -sf ~/.kubectx/completion/kubectx.bash $COMPDIR/kubectx

    cat << FOE >> ~/.bashrc
    #kubectx and kubens
    export PATH=~/.kubectx:\$PATH
    FOE
    ```

1. [Kube Prompt](https://github.com/jonmosco/kube-ps1)
    ```shell
    git clone -b v0.7.0 https://github.com/jonmosco/kube-ps1.git ~/.kube-ps1
    cat << FOE >> ~/.bashrc

    #kube-ps1
    source ~/.kube-ps1/kube-ps1.sh
    export PS1+='\$(kube_ps1)'
    kubeoff
    FOE

    bash -l
    ```
