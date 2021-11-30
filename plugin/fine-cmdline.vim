if exists('g:loaded_fine_cmdline')
  finish
endif
let g:loaded_fine_cmdline = 1

command! -nargs=? FineCmdline lua require('fine-cmdline').open({default_value = <q-args>})

