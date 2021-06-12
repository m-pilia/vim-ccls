# hadolint ignore=DL3007
FROM testbed/vim:latest

RUN install_vim -tag v8.2.0528 -build \
                -tag neovim:v0.4.3 -build

# hadolint ignore=DL3018
RUN apk --update --no-cache add \
        bash \
        git \
        python3 \
        py-pip \
&&  python3 -m pip install --no-cache-dir \
        vim-vint==0.3.21 \
&&  git clone https://github.com/junegunn/vader.vim vader \
&&  git --work-tree=vader --git-dir=vader/.git checkout c6243dd81c9
