/**
 * Terminal Emulator display to look like commands are being typed and output is
 * being generated.
 *
 * Author: Dave Eddy <dave@daveeddy.com>
 * Date: April 05, 2025
 * License: MIT
 */

const TYPING_SPEED = 110;
const INITIAL_DELAY = 2200;
const SUBSEQUENT_DELAY = 5000;

const CURSOR_BLINK_START = 1;
const CURSOR_BLINK_END = 2;

const terminal = document.getElementById('main-terminal').children[0];

function runCommand(i, cb) {
    let o = COMMANDS[i];
    let lines = o.lines;
    let command = o.cmd.split('');

    let output = lines.map((line) => line + '\n');

    let items = [].concat(
        CURSOR_BLINK_END,
        command,
        ['\n'],
        output,
        '$ ',
        CURSOR_BLINK_START,
    );

    // load the prompt (clear the terminal)
    blinkCursorStart();
    terminal.innerHTML = '$ ';

    // simulate typing the command
    i = 0;
    function type() {
        delay = SUBSEQUENT_DELAY;
        if (i === items.length) {
            // done!
            cb();
            return;
        }

        let c = items[i];
        i++;

        switch (c) {
            case CURSOR_BLINK_START:
                blinkCursorStart();
                break;
            case CURSOR_BLINK_END:
                blinkCursorEnd();
                break;
            default:
                terminal.innerHTML += c;
                break;
        }

        setTimeout(type, TYPING_SPEED);
    }
    type();
}

function blinkCursorStart() {
    terminal.classList.remove('no-animation');
}

function blinkCursorEnd() {
    terminal.classList.add('no-animation');
}

function main() {
    terminal.innerHTML = '$ ';

    let i = 0;
    let max = COMMANDS.length;

    let delay = INITIAL_DELAY;

    // if only one example command is found don't cycle through them - just
    // finish once its loaded
    function noop() {};
    let cb = max === 1 ? noop : loop;

    function loop() {
        setTimeout(function () {
            delay = SUBSEQUENT_DELAY;
            runCommand(i, cb);
            i = (i + 1) % max;
        }, delay);
    }
    loop();
}

main();
