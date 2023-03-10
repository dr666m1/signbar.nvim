# signbar.nvim
A neovim plugin to show the signs like a minimap.

https://user-images.githubusercontent.com/26474260/218783909-61a7c12b-dd37-40a5-b590-38ebd491670e.mp4

## Installation
Use your favorite pacakge manager.

e.g. with [packer](https://github.com/wbthomason/packer.nvim):

```lua
use { "dr666m1/signbar.nvim" }
```

## Setup

```lua
require("signbar").setup {
  -- by default signbar is refreshed on every cursor move
  -- if refresh_interval is too short, E322 may occur
  refresh_interval = 1000, -- milliseconds, default: nil

  -- :sign place group=* is useful to list sign groups and names
  ignored_sign_names = { "Marks_a" }, -- default: {}
  ignored_sign_groups = { "MarkSigns" }, -- default: {}
}
```

## Contributing
If you find any bugs, feel free to create an issue.
PRs are also welcome but please create an issue before introducing a new feature.

## See also
If you are interested in the plugins used in the video, check out these awesome repositories!

* [marks.nvim](https://github.com/chentoast/marks.nvim)
* [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)
