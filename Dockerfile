 
FROM archlinux/archlinux:base-devel as builder

RUN pacman -Syu --needed --noconfirm git

# makepkg user 
ARG user=builder
ARG threads=20
RUN useradd --system --create-home $user \
  && echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
USER $user
WORKDIR /tmp

# Install yay 
RUN git clone https://aur.archlinux.org/yay-bin.git \
  && cd yay-bin \
  && makepkg -sri --needed --noconfirm

# Bild aom-av1-lavish
RUN MAKEFLAGS="-j$threads" yay -Sa libjxl-metrics-git --noconfirm
RUN MAKEFLAGS="-j$threads" yay -Sa vmaf-git --noconfirm 
RUN sudo pacman -Rdd aom --noconfirm
RUN MAKEFLAGS="-j$threads" yay -Sa aom-av1-lavish-git --noconfirm

# modify av1an docker
FROM masterofzen/av1an:master
COPY --from=builder /home/builder/.cache/yay/* /tmp/
USER root
RUN pacman -Rdd vmaf aom --noconfirm \
  && pacman -U /tmp/highway-git* /tmp/libjxl-metrics-git* /tmp/vmaf-git* /tmp/aom-av1-lavish-git* --noconfirm \
  && rm -r /tmp/*
USER app_user