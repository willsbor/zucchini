# Zucchini

[![Build Status](https://api.travis-ci.org/zucchini-src/zucchini.png)](http://travis-ci.org/zucchini-src/zucchini)
[![Coverage Status](https://coveralls.io/repos/zucchini-src/zucchini/badge.png)](https://coveralls.io/r/zucchini-src/zucchini)
[![Gem Version](https://badge.fury.io/rb/zucchini-ios.png)](http://badge.fury.io/rb/zucchini-ios)

## Requirements

 1. Mac OS X 10.6 or newer
 2. XCode 4.2 or newer
 3. Ruby 1.9.3 or newer
 4. A few command line tools which can be installed with [homebrew](http://brew.sh/):

```
brew update && brew install imagemagick node
npm install -g coffee-script
```

## Start using Zucchini

```
gem install zucchini-ios
```

Using Zucchini doesn't involve making any modifications to your application code.
You might as well keep your Zucchini tests in a separate project.

To create a project scaffold:

```
zucchini generate --project /path/to/my_project
```

Then to create a feature scaffold for your first feature:

```
zucchini generate --feature /path/to/my_project/features/my_feature
```

Start developing by editing `features/my_feature/feature.zucchini` and `features/support/screens/welcome.coffee`.

Make sure you check out the [zucchini-demo](https://github.com/zucchini-src/zucchini-demo) project featuring an easy to explore Zucchini setup around Apple's CoreDataBooks sample.

## Running on the device

Add your device to `features/support/config.yml`.

The [udidetect](https://github.com/vaskas/udidetect) utility comes in handy if you plan to add devices from time to time: `udidetect -z`.

```
ZUCCHINI_DEVICE="My Device" zucchini run /path/to/my_feature
```
You can set one of the devices to be used by default in `config.yml` so that you can avoid setting `ZUCCHINI_DEVICE` each time:

```
devices:
  My Device:
	default: true
	...
```

## Running on the iOS Simulator

We encourage you to run your Zucchini features on real hardware. However you can also run them on the iOS Simulator.

First off, modify your `features/support/config.yml` to include the path to your compiled app (relative or absolute), e.g.

```
app: ./Build/Products/Debug-iphonesimulator/CoreDataBooks.app
```

Secondly, add a simulator device entry (no UDID needed) and make sure you provide the actual value for `screen` based on your iOS Simulator settings:

```
devices:
  My Simulator:
    screen: retina_ios7
    simulator: iPhone (Retina 4-inch)
    ...
```

You can also override the app path per device:

```
devices:
  iPad2:
    screen: ipad_ios6
    app: ./Build/Products/Debug-iphoneos/CoreDataBooks.app
```

Note that `config.yml` is compiled through ERB so that you can use environment variables, e.g.

```erb
app: <%= ENV['ZUCCHINI_APP'] %>
```


Run Zucchini and watch the simulator go!

```
ZUCCHINI_DEVICE="My Simulator" zucchini run /path/to/my_feature
```

## See also

### Built-in help

```
zucchini --help
zucchini run --help
zucchini generate --help
```

### Further reading

* [Zucchini features on the inside](https://github.com/zucchini-src/zucchini/wiki/Features-on-the-inside)
* [Continuous Integration with Zucchini](https://github.com/zucchini-src/zucchini/wiki/CI)
* [Automated iOS Testing with Zucchini](http://www.jacopretorius.net/2013/04/automated-ios-testing-with-zucchini.html) - a tutorial by [@Jaco-Pretorius](https://github.com/Jaco-Pretorius)
* [Zucchini Google Group](https://groups.google.com/forum/#!forum/zucchini-discuss)

## Credits
* [Zucchini contributors](https://github.com/zucchini-src/zucchini/graphs/contributors) also known as the awesome [CHANGELOG](https://github.com/zucchini-src/zucchini/blob/master/CHANGELOG.md) guys
* [Rajesh Kumar](https://github.com/rajbeniwal) for alpha and beta testing, ideas and the initial feedback
* [Kevin O'Neill](https://github.com/kevinoneill) for the original idea and inspiration
* [PlayUp](http://www.playup.com/) where the project was born and first released.
