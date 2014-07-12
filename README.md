About
-----

`cashe` is a bash script which is two things:

  1. An addon to `cron` which allows you to run tasks in increments of seconds
     rather than minutes.
  2. A cache for command output.

So `cashe` will cache the output of a given command for seconds number of
seconds, and then regenerate it when it becomes out of date.

The use-case is for my `zsh` statusline: it shows battery percentage and online
status, but querying for those things is expensive. And of course repeating
code twice is a sin...

Requirements
------------

`cashe` requires GNU `stat` and `bash` (but it might work with `sh`). BSD
`stat` doesn't work. You also need a filesystem with reliable file modification
times.

Installation
------------

Install `cashe.sh` somewhere:

    $ mv cashe.sh /usr/local/bin/cashe
    $ chmod +x /usr/local/bin/cashe

Make a `.cashe` directory in your home directory. This is where your `cashe`
configuration lives:

    $ mkdir -p ~/.cashe

Add a `cashe update` invocation to your crontab. For example, run `crontab -e`
and add this line:

    * * * * * /usr/local/bin/cashe update

Usage
-----

`cashe` has two invocations: `update`, which regenerates any out-of-date
output, and `read`, which reads that output.

Run `cashe update` to regenerate all out-of-date targets, or `cashe update
<target>` to regenerate the output of target `target` if it is out of date.

Run `cashe read <target>` to read the output for the target `target`. If that
target hasn't been generated, `cashe` will not print anything and will return
`1`; otherwise it will print the output for that target and return `0`.
Reading will never cause the output to be generated.

Configuration
-------------

Files of the form `~/.cashe/my-target-name.cashe` are detected by `cashe` as
targets. They consist of any number of lines whose first word is a setting
and the remainder the arguments to that setting. For example:

    command /bin/echo Hello, world!
    time-to-live 10
    output-file hello-world.output

The keys are as follows:

    * `command`: Required. The command to run. Since `cron` runs without a
      `$PATH` (at least on my system), you should specify an absolute path to
the program to run. You can pass arguments to that command.
    * `time-to-live`: Optional. The amount of time before the output should be
      regenerated, in seconds. Defaults to `1`, which is probably not what you
want.
    * `output-file`: Optional. The file to write the output to. If it's a
      relative path, it is treated with the working directory as `~/.cashe`;
that is, something like `my-output.output` will write to
`~/.cashe/my-output.output`. Defaults to the name of the target with the the
extension `.output`.

License
-------

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
