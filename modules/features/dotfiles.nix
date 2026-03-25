{ ... }:
{
  flake.nixosModules.dotfiles = { ... }:
  let
    dotfilesPath = "/home/kschoon/git-local/kevinschoonover/localhost/dotfiles";
  in
  {
    system.activationScripts.dotfiles = ''
      mkdir -p /home/kschoon/.config

      # Symlink .config/<app> directories (stow layout: <app>/.config/<app>)
      for app in nvim kitty; do
        ln -sfn "${dotfilesPath}/$app/.config/$app" "/home/kschoon/.config/$app"
      done

      # Symlink individual dotfiles
      ln -sf "${dotfilesPath}/tmux/.tmux.conf" /home/kschoon/.tmux.conf
      ln -sf "${dotfilesPath}/git/.gitconfig" /home/kschoon/.gitconfig

      # Fix ownership
      chown -h kschoon:users /home/kschoon/.config/{nvim,kitty}
      chown -h kschoon:users /home/kschoon/.tmux.conf /home/kschoon/.gitconfig
    '';
  };
}
