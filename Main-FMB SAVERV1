import tkinter as tk
import threading
import time
import mss
import numpy as np
import cv2
from pynput.mouse import Listener as MouseListener
from pynput.keyboard import Listener as KeyboardListener
import os
import sys
import json
import random
from datetime import datetime

# === CONFIG ===
ROAST_DURATION_SECONDS = 4
SAVE_FILE = "Fucking-Data.json"

# Global state
overlay_active = False
current_mouse_pos = (0, 0)
button_template = None
selection_mode = False
caught_count = 0
detection_running = True

# Try to import everything with fallbacks
try:
    import cv2
    import mss
    from pynput.mouse import Listener as MouseListener
    from pynput.keyboard import Listener as KeyboardListener
    from PIL import ImageGrab
    import numpy as np
except ImportError as e:
    print(f"\n{'=' * 60}")
    print("MISSING DEPENDENCIES - RUN THIS TO FIX:")
    print(f"{'=' * 60}")
    print("\npip install opencv-python mss pynput pillow numpy\n")
    print("Then restart the script.")
    print(f"{'=' * 60}\n")
    input("Press Enter to exit...")
    sys.exit(1)


def load_save_data():
    global caught_count
    if os.path.exists(SAVE_FILE):
        try:
            with open(SAVE_FILE, 'r') as f:
                data = json.load(f)
                caught_count = data.get('caught_count', 0)
                print(f"\n[LOADED] Previous shame count: {caught_count} times")
                print(f"[LOADED] Last session: {data.get('last_session', 'unknown')}")
        except:
            print("\n[ERROR] Could not load save file. Starting fresh.")
            caught_count = 0
    else:
        print("\n[FRESH START] No save file found. Beginning your shame journey.")
        caught_count = 0


def save_progress():
    global caught_count
    try:
        data = {
            'caught_count': caught_count,
            'last_session': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            'total_roasts': caught_count
        }
        with open(SAVE_FILE, 'w') as f:
            json.dump(data, f, indent=4)
    except:
        pass


def show_instructions():
    print("=" * 60)
    print("FUCKING INSTANT SHAME SYSTEM - ZERO FUCKS EDITION")
    print("=" * 60)
    print(f"\nYOUR SHAME RECORD: {caught_count} catches")
    print("\nFUCKING SETUP YOU DUMBASS:")
    print("   1. FUCKING PRESS THE FUCKING 'S' KEY")
    print("   2. FUCKING CLICK AND FUCKING DRAG A TIGHT BOX AROUND THE FUCKING GREEN FUCKING BUY BUTTON")
    print("   3. AND FUCKING RELEASE THE FUCKING MOUSE")
    print("   4. FUCKING HOVER = INSTANT FUCKING ROAST (FUCKING 0ms DELAY)")
    print("\nPRESS 'Q' TO GET THE FUCK OUT\n")


class SelectionOverlay:
    def __init__(self):
        self.root = None
        self.canvas = None
        self.rect = None
        self.start_x = None
        self.start_y = None

    def create(self):
        self.root = tk.Tk()
        self.root.attributes("-fullscreen", True)
        self.root.attributes("-topmost", True)
        self.root.configure(bg="black")
        self.root.attributes("-alpha", 0.3)
        self.root.overrideredirect(True)

        self.canvas = tk.Canvas(self.root, highlightthickness=0, bg="black")
        self.canvas.pack(fill=tk.BOTH, expand=True)

        self.canvas.bind("<ButtonPress-1>", self.on_mouse_down)
        self.canvas.bind("<B1-Motion>", self.on_mouse_drag)
        self.canvas.bind("<ButtonRelease-1>", self.on_mouse_up)
        self.root.bind("<Escape>", lambda e: self.cancel())

        instr_label = tk.Label(
            self.root,
            text="FUCKING DRAW A FUCKING TIGHT FUCKING BOX AROUND THE FUCKING GREEN FUCKING BUY BUTTON ONLY\nFUCKING PRESS ESC TO FUCKING CANCEL",
            font=("Arial", 18, "bold"),
            fg="red",
            bg="black",
            justify="center"
        )
        instr_label.place(relx=0.5, y=50, anchor="n")

        self.root.mainloop()

    def on_mouse_down(self, event):
        self.start_x = event.x_root
        self.start_y = event.y_root
        if self.rect:
            self.canvas.delete(self.rect)

    def on_mouse_drag(self, event):
        if self.start_x and self.start_y:
            if self.rect:
                self.canvas.delete(self.rect)
            self.rect = self.canvas.create_rectangle(
                self.start_x, self.start_y,
                event.x_root, event.y_root,
                outline="red", width=3, fill="red", stipple="gray50"
            )

    def on_mouse_up(self, event):
        global button_template, selection_mode

        end_x, end_y = event.x_root, event.y_root
        x1 = min(self.start_x, end_x)
        y1 = min(self.start_y, end_y)
        x2 = max(self.start_x, end_x)
        y2 = max(self.start_y, end_y)

        screenshot = ImageGrab.grab(bbox=(x1, y1, x2, y2))
        button_template = cv2.cvtColor(np.array(screenshot), cv2.COLOR_RGB2BGR)

        cv2.imwrite("buy_button_template.png", button_template)

        print(f"\nFUCKING BUTTON CAPTURED! Size: {button_template.shape[1]}x{button_template.shape[0]}")
        print(f"YOUR SHAME CONTINUES FROM {caught_count} CATCHES")
        print("INSTANT FUCKING SHAME MODE ACTIVATED - 0ms DELAY\n")

        selection_mode = False
        self.root.destroy()

    def cancel(self):
        global selection_mode
        selection_mode = False
        self.root.destroy()
        print("\nFUCKING CANCELLED")
        sys.exit(0)


def find_button_fast(screenshot, template):
    if template is None:
        return []

    h, w = template.shape[:2]

    screenshot_gray = cv2.cvtColor(screenshot, cv2.COLOR_BGR2GRAY)
    template_gray = cv2.cvtColor(template, cv2.COLOR_BGR2GRAY)

    result = cv2.matchTemplate(screenshot_gray, template_gray, cv2.TM_CCOEFF_NORMED)
    locations = np.where(result >= 0.82)

    matches = []
    for pt in zip(*locations[::-1]):
        x, y = pt
        matches.append({
            'x_min': x,
            'x_max': x + w,
            'y_min': y,
            'y_max': y + h,
        })

    if len(matches) > 1:
        matches = merge_quick(matches, 15)

    return matches


def merge_quick(boxes, threshold):
    if not boxes:
        return []

    merged = []
    for box in boxes:
        if not merged:
            merged.append(box)
        else:
            last = merged[-1]
            if (box['x_min'] <= last['x_max'] + threshold and
                    box['y_min'] <= last['y_max'] + threshold):
                last['x_min'] = min(last['x_min'], box['x_min'])
                last['x_max'] = max(last['x_max'], box['x_max'])
                last['y_min'] = min(last['y_min'], box['y_min'])
                last['y_max'] = max(last['y_max'], box['y_max'])
            else:
                merged.append(box)
    return merged


def is_hovering_button(mouse_x, mouse_y, buttons):
    for button in buttons:
        if (button['x_min'] <= mouse_x <= button['x_max'] and
                button['y_min'] <= mouse_y <= button['y_max']):
            return True
    return False


class InstantRoastOverlay:
    def __init__(self):
        self.root = None
        self.active = False

    def get_roast_style(self, count):
        # Category 1: Femboy (5-20)
        if 5 <= count <= 20 and count % 5 == 0:
            if count == 5:
                text = f"""~ HELLO CUTIE ~

ur about to waste robux again meow~

this accessory is pure bullshit daddy~

step away and touch some grass~

- get outta here cutie ~

stopped your dumbass: {count} times~"""
            elif count == 10:
                text = f"""~ UWU NOT AGAIN ~

daddy please stop trying to waste robux~

this bullshit accessory isnt worth it meow~

step away from the fucking button~

- go touch some grass cutie ~

caught you {count} times already~"""
            elif count == 15:
                text = f"""~ SERIOUSLY DADDY ~

10 times wasnt enough meow~

now youre at {count} attempts~

this is pure bullshit get out~

- step away and breathe ~

caught your dumbass: {count} times~"""
            else:
                text = f"""~ OK THIS IS GETTING SAD ~

daddy youve been caught {count} times~

at this point just uninstall roblox~

touch some fucking grass for real~

- meow goodbye cutie ~"""
            return {
                'bg': "#FF69B4",
                'fg': "#FF1493",
                'font': ("Comic Sans MS", 28, "bold"),
                'text': text
            }

        # Category 2: Existential Dread (25-40)
        elif 20 < count <= 40 and count % 5 == 0:
            texts = [
                f"""[EXISTENTIAL SHAME]

{count} times.

The femboys have left.
The grass is dying.
Your robux is crying.

What are you even doing with your life?

~ disappointed system""",

                f"""[REALITY CHECK]

{count} catches.

You could have learned a language.
You could have worked out.
Instead you're here. Hovering. Again.

Touch grass.
Please.

~ management""",

                f"""[THE VOID SPEAKS]

{count} times youve done this.

The buy button is not your friend.
It never was.
Step away before its too late.

~ from the abyss""",

                f"""[INTERVENTION MODE]

{count} attempts.

Your future self is crying.
Your wallet is crying.
Even the femboys are crying.

Just close Roblox.

~ therapist on speed dial"""
            ]
            selected = random.choice(texts)
            return {
                'bg': "#1a1a2e",
                'fg': "#e94560",
                'font': ("Courier New", 28, "bold"),
                'text': selected
            }

        # Category 3: Pure Disappointment (45-60)
        elif 40 < count <= 60 and count % 5 == 0:
            texts = [
                f"""[DAD DISAPPOINTMENT]

{count} times.

Im not angry.
Im just disappointed.
You had potential.
Now you have {count} roast logs.

~ dad.exe""",

                f"""[SELF DESTRUCTION DETECTED]

{count} hover attempts.

Theres no saving you anymore.
Youre beyond help.
But heres a roast anyway.

~ system overload""",

                f"""[WASTE OF POTENTIAL]

{count} times youve done this.

You could have bought Korblox twice by now.
Instead youre here.
Getting roasted.
By a script.

~ think about that""",

                f"""[PITY MODE ACTIVATED]

{count} catches.

I dont even want to roast you anymore.
Its just sad.
Like watching a fish drown.

~ sigh"""
            ]
            selected = random.choice(texts)
            return {
                'bg': "#2d2d2d",
                'fg': "#ffcc00",
                'font': ("Impact", 32, "bold"),
                'text': selected
            }

        # Category 4: Aggressive Shame (65-80)
        elif 60 < count <= 80 and count % 5 == 0:
            texts = [
                f"""[SHAME LEVEL: OVER 9000]

{count} FUCKING TIMES.

YOU ARE ACTUALLY BRAINDEAD.
THE BUTTON ISNT GOING ANYWHERE.
STEP THE FUCK AWAY.

~ screaming""",

                f"""[ENOUGH]

{count} HOVERS.

YOU HAVE A PROBLEM.
WE ALL SEE IT.
GET HELP.

~ FOR YOUR OWN GOOD""",

                f"""[WAKE THE FUCK UP]

{count} CATCHES.

YOUR ROBUX IS BURNING.
YOUR TIME IS WASTING.
YOUR BRAIN IS ROTTING.

STOP.

~ reality""",

                f"""[BRUTAL MODE]

{count} times you failed.

At this point Korblox is the least of your problems.
You need a life coach.
And a therapist.
And grass.

~ good luck"""
            ]
            selected = random.choice(texts)
            return {
                'bg': "#4a0000",
                'fg': "#ff0000",
                'font': ("Arial Black", 32, "bold"),
                'text': selected
            }

        # Category 5: Absurd Humor (85-100)
        elif 80 < count <= 100 and count % 5 == 0:
            texts = [
                f"""[RECORD BREAKER]

{count} ATTEMPTS.

The buy button has filed a restraining order.
The grass has moved to another country.
Your robux has disowned you.

~ congratulations?""",

                f"""[WORLD RECORD]

{count} catches.

You are officially the most roasted person alive.
Scientists are studying you.
The femboys wrote a book about you.
Its called "Why Tho"

~ fame""",

                f"""[LEGENDARY STATUS]

{count} times.

Some people climb mountains.
Some cure diseases.
You hover over buy buttons.
We are not the same.

~ disappointed legend""",

                f"""[ABSOLUTE MADMAN]

{count} hovers.

At this point Im impressed.
Not in a good way.
But impressed nonetheless.

~ confused system"""
            ]
            selected = random.choice(texts)
            return {
                'bg': "#0a0a0a",
                'fg': "#00ff00",
                'font': ("Courier New", 30, "bold"),
                'text': selected
            }

        # Category 6: Ascended Shame (105-120)
        elif 100 < count <= 120 and count % 5 == 0:
            texts = [
                f"""[TRANSCENDENCE]

{count} catches.

You have ascended beyond shame.
You are one with the buy button.
The roast no longer affects you.
But I will try anyway.

~ zen master""",

                f"""[ENLIGHTENMENT]

{count} times.

The button is you.
You are the button.
Hovering is meaningless.
Buying is suffering.

~ buddha probably""",

                f"""[DETACHMENT]

{count} catches.

I cannot shame someone who has no shame left.
You are empty.
Like your wallet would be.
If you kept buying.

~ void""",

                f"""[THE CYCLE CONTINUES]

{count} attempts.

Nothing changes.
You hover.
I roast.
The sun rises.

~ eternal"""
            ]
            selected = random.choice(texts)
            return {
                'bg': "#000033",
                'fg': "#88ff88",
                'font': ("Georgia", 28, "italic"),
                'text': selected
            }

        # Category 7: Beyond (125+)
        elif count > 120 and count % 5 == 0:
            texts = [
                f"""[GOD MODE]

{count} times.

You have broken the simulation.
There is no roast left.
Only you.
And the button.

~ admin""",

                f"""[INFINITE SHAME]

{count} catches.

The counter has no meaning anymore.
Time has no meaning.
You are eternal.
So is your bad decision making.

~ forever""",

                f"""[THE FINAL ROAST]

{count} attempts.

I have nothing left.
You win.
But at what cost?

~ fin."""
            ]
            selected = random.choice(texts)
            return {
                'bg': "#000000",
                'fg': "#ffffff",
                'font': ("Impact", 34, "bold"),
                'text': selected
            }

        # Normal aggressive (all other catches not divisible by 5)
        else:
            normal_roasts = [
                f"""UR MF ASS IS ABOUT TO WASTE ROBUX DUMBASS

THIS FUCKING ACCESSORY OR WHATEVER IS
PURE BULLSHIT

STEP AWAY AND
TOUCH SOME FUCKING GRASS

Get the FUCK outta here
Next 5 times i catch you i promise im sending femboys to you
(lowkey a W but dont rely on it bitch)

Stopped your dumbass again bitch: {count} times""",

                f"""ARE YOU FUCKING KIDDING ME

YOU AGAIN? REALLY?
DONT YOU HAVE ANYTHING BETTER TO DO?

THERE ARE BILLIONS OF PEOPLE IN THE WORLD
AND YOURE HERE
HOVERING OVER A FUCKING BUY BUTTON

GO TOUCH GRASS YOU ABSOLUTE WASTE OF SPACE

Caught: {count} times""",

                f"""STOP. JUST FUCKING STOP.

WHAT IS WRONG WITH YOU?
DID YOUR PARENTS DROP YOU AS A CHILD?

THIS BUTTON ISNT EVEN THAT COOL
THE ACCESSORY IS UGLY
YOUR ROBUX IS BETTER OFF SAVED

GET THE FUCK OUT

Count: {count}""",

                f"""YOU AGAIN?

I SWEAR TO GOD IF I SEE YOU ONE MORE TIME
Im actually going to lose it

THE DEFINITION OF INSANITY IS DOING THE SAME THING
OVER AND OVER AND EXPECTING DIFFERENT RESULTS

YOU ARE THE DEFINITION OF INSANITY

Caught your dumbass: {count} times""",

                f"""BROTHER PLEASE

SEEK HELP
THERAPY
A HOBBY
SOMETHING

ANYTHING IS BETTER THAN HOVERING OVER A FUCKING BUY BUTTON
FOR THE {count}TH TIME

IM BEGGING YOU
TOUCH SOME GRASS""",

                f"""YOU KNOW WHAT?

I DONT EVEN HAVE WORDS ANYMORE
YOUVE DONE IT {count} TIMES
AND YOURE STILL HERE

THE AUDACITY
THE NERVE
THE SHEER FUCKING BALLS

JUST GO AWAY ALREADY""",

                f"""CONGRATULATIONS

YOU HAVE WASTED {count} HOVERS OF YOUR LIFE
THAT YOU WILL NEVER GET BACK

TIME IS MONEY
AND YOURE WASTING BOTH

HOPE YOURE PROUD OF YOURSELF

~ not proud of you"""

                f"""I WAS IN THE MIDDLE OF SOMETHING

AND YOU HAD TO RUIN IT BY HOVERING AGAIN

DO YOU HAVE ANY IDEA HOW ANNOYING YOU ARE?
THE SCRIPT IS ANNOYED. IM ANNOYED. EVERYONE IS ANNOYED.

JUST FUCKING STOP

Count: {count}"""
            ]

            if count == 69:
                text = f"""NICE

UR ABOUT TO WASTE ROBUX DUMBASS

THIS ACCESSORY IS PURE BULLSHIT

STEP AWAY AND TOUCH SOME GRASS

Get the fuck outta here

Caught your dumbass: {count} times"""
            else:
                text = random.choice(normal_roasts)

            return {
                'bg': "white",
                'fg': "red",
                'font': ("Arial Black", 32, "bold"),
                'text': text
            }

    def show(self, count):
        if self.active:
            return

        self.active = True

        self.root = tk.Tk()
        self.root.attributes("-fullscreen", True)
        self.root.attributes("-topmost", True)
        self.root.overrideredirect(True)
        self.root.lift()

        style = self.get_roast_style(count)

        self.root.configure(bg=style['bg'])

        frame = tk.Frame(self.root, bg=style['bg'])
        frame.pack(expand=True, fill="both")

        label = tk.Label(
            frame,
            text=style['text'],
            font=style['font'],
            fg=style['fg'],
            bg=style['bg'],
            justify="center"
        )
        label.pack(expand=True)

        self.root.after(10, lambda: self.root.attributes("-topmost", True))
        self.root.after(int(ROAST_DURATION_SECONDS * 1000), self.close)

        self.root.mainloop()

    def close(self):
        self.active = False
        if self.root:
            self.root.destroy()
            self.root = None


roast_overlay = None


def trigger_instant_roast():
    global roast_overlay, caught_count

    if roast_overlay is None:
        roast_overlay = InstantRoastOverlay()

    if not roast_overlay.active:
        caught_count += 1
        save_progress()
        print(f"\nINSTANT FUCKING ROAST! - Hover detected (Caught: {caught_count} times)")
        thread = threading.Thread(target=roast_overlay.show, args=(caught_count,), daemon=True)
        thread.start()


def monitoring_loop():
    global button_template, current_mouse_pos, detection_running

    print("\n" + "=" * 60)
    print("INSTANT FUCKING SHAME MODE ACTIVE")
    print("=" * 60)
    print(f"Button template: {button_template.shape[1]}x{button_template.shape[0]}")
    print(f"YOUR LIFETIME SHAME: {caught_count} catches")
    print("Hover over button = INSTANT fucking roast (0ms delay)")
    print("Move mouse away = screen clears")
    print("Press 'q' to get the fuck out\n")

    with mss.mss() as sct:
        monitor = sct.monitors[1]
        frame_count = 0
        fps_start = time.time()
        was_hovering = False
        last_match_count = 0

        while detection_running:
            try:
                screenshot_np = np.array(sct.grab(monitor))
                screenshot = cv2.cvtColor(screenshot_np, cv2.COLOR_BGRA2BGR)

                buttons = find_button_fast(screenshot, button_template)

                mouse_x, mouse_y = current_mouse_pos
                is_hovering = is_hovering_button(mouse_x, mouse_y, buttons)

                if is_hovering and not was_hovering:
                    trigger_instant_roast()

                was_hovering = is_hovering
                last_match_count = len(buttons)

                frame_count += 1
                if time.time() - fps_start >= 1:
                    print(
                        f"\rScan speed: {frame_count} FPS | Buttons: {last_match_count} | Hovering: {'FUCK YES' if is_hovering else 'NO'} | Caught: {caught_count}    ",
                        end="")
                    frame_count = 0
                    fps_start = time.time()

                time.sleep(0.0005)

            except Exception as e:
                print(f"\nFucking error: {e}")
                time.sleep(0.001)


def on_mouse_move(x, y):
    global current_mouse_pos
    current_mouse_pos = (x, y)


def on_key_press(key):
    global selection_mode, detection_running

    try:
        if hasattr(key, 'char'):
            if key.char == 's' and not selection_mode and button_template is None:
                selection_mode = True
                print("\nFUCKING DRAW A TIGHT BOX AROUND THE GREEN FUCKING BUY BUTTON...")
                overlay = SelectionOverlay()
                overlay.create()
            elif key.char == 'q':
                save_progress()
                print(f"\n\n[SAVED] Your shame count {caught_count} has been recorded for next time.")
                print("Goodbye. Go touch some grass.")
                detection_running = False
                return False
    except:
        pass


def main():
    global button_template

    load_save_data()
    show_instructions()

    if os.path.exists("buy_button_template.png"):
        print("Loading saved fucking button...")
        button_template = cv2.imread("buy_button_template.png")
        print(f"Loaded: {button_template.shape[1]}x{button_template.shape[0]}")

        mouse_listener = MouseListener(on_move=on_mouse_move)
        mouse_listener.start()

        keyboard_listener = KeyboardListener(on_press=on_key_press)
        keyboard_listener.start()

        monitoring_loop()

        mouse_listener.stop()
        keyboard_listener.stop()
    else:
        print("PRESS THE FUCKING 'S' KEY TO SELECT THE FUCKING BUY BUTTON...\n")

        keyboard_listener = KeyboardListener(on_press=on_key_press)
        keyboard_listener.start()

        mouse_listener = MouseListener(on_move=on_mouse_move)
        mouse_listener.start()

        try:
            while button_template is None:
                time.sleep(0.05)
        except KeyboardInterrupt:
            print("\n\nFucking cancelled")
            return


if __name__ == "__main__":
    main()
