# Swiss railway clock for conky

A conky clock by Jochen Keil (2013) based upon Alison Pitt's Air Clock (2009)

This clock is designed to resemble the swiss railway clock:

[Wikipedia article](https://en.wikipedia.org/wiki/Swiss_railway_clock)

[Animated gif](https://upload.wikimedia.org/wikipedia/de/7/7c/Minutensprunguhr_animiert.gif):

<img src="https://upload.wikimedia.org/wikipedia/de/7/7c/Minutensprunguhr_animiert.gif"
  alt="Animated gif of railway clock" width="150" height="150" />

From the wikipedia article:
> [..]
> The second hand is driven by an electrical motor independent of the
> master clock. It requires only about 58.5 seconds to circle the face, then the
> hand pauses briefly at the top of the clock. It starts a new rotation as soon
> as it receives the next minute impulse from the master clock
> [..]

This clock also rotates smoothly without "ticks". It will also stop on top for
a configureable delay (look out for the global `delay` value).

The main drawback is resource usage. For smooth circulation, conky needs to be
updated every 0.1 second. Therefore I strongly recommend to run this in
a seperate conky process.

Additionally, if `update_interval` is larger than 1 the seconds hand is not
drawn. Hence, to save battery set `update_interval_on_battery` to 30 or so.
