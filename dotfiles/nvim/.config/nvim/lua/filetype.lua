vim.g.do_filetype_lua = 1

vim.filetype.add({
  filename = {
    Tmuxfile = 'tmux',
    ['go.sum'] = 'go',
    ['yarn.lock'] = 'yaml',
  },
  pattern = {
    ['%.config/git/users/.*'] = 'gitconfig',
    ['.*/playbooks/.*%.yaml'] = 'yaml.ansible',
    ['.*/playbooks/.*%.yml'] = 'yaml.ansible',
    ['.*/roles/.*%.yaml'] = 'yaml.ansible',
    ['.*/roles/.*%.yml'] = 'yaml.ansible',
    ['.*/site.yml'] = 'yaml.ansible',
    ['.*/inventory/.*%.ini'] = 'ansible_hosts',
  },
})
