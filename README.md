This project helps you build C++ modules for Node.js using the CMake meta build system.

[![NPM](https://nodei.co/npm/@mapbox/cmake-node-module.png)](https://nodei.co/npm/node-addon-api/)

While the default way of building Node.js C++ modules is to use [node-gyp](https://github.com/nodejs/node-gyp), there's no requirement to do so. If your project already uses CMake, for example, you can use this project to directly build C++ Node.js modules.

Unlike other CMake-based Node.js module build scripts, this project allows you to generate **multiple ABI version of a Node.js module** within the same build through the use of _interface targets_.

## Getting started

Add the `@mapbox/cmake-node-module` as a dependency to your `package.json` file.

In your `CMakeLists.txt` file, add this to get a very simple Node.js module to build

```cmake
include(node_modules/@mapbox/cmake-node-module/module.cmake)

add_node_module(module)

target_sources(module INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/module.cpp
)
```

To support building multiple ABIs, `add_node_module` creates a number of different targets: One interface target with the name you pass to the function, and one shared library target for every Node.js ABI. By default, `add_node_module` creates targets for all ABIs >= 46 (Node.js 4).

## ABIs vs. versions

Note that this module works with *ABI* versions, not *Node.js* versions: Multiple Node.js versions can support the same ABI, so it's not necessary to create a separate Node.js module per *version*, only per *ABI*. The Node.js website has an [overview of all versions and how they map to ABIs](https://nodejs.org/en/download/releases/). This means that this CMake script may download headers that are *newer* than the Node.js version you have installed on your computer. It'll also download headers that are older than the version you have installed to support building for older ABIs.

## Documentation

### Global variables

* `NODE_MODULE_MINIMUM_ABI` (defaults to `46`): Determines the minimum ABI that this script will generate targets for.
* `NODE_MODULE_CACHE_DIR` (defaults to `${CMAKE_BINARY_DIR}`): Determines where the Node.js and Nan headers should be cached.

You can change these variables before or after you've included the `.cmake` file, or pass them on the command line when invoking CMake. However, in most cases it is not necessary since you can also override them for every Node.js module target that you create.

### Functions

```
add_node_module(<name>
                [ NAN_VERSION <version> ]
                [ MINIMUM_NODE_ABI <number> ]
                [ INSTALL_PATH <path> ]
                [ CACHE_DIR <directory> ]
                [ EXCLUDE_NODE_ABIS <number> [<number>...] ]
               )
```

Use this function to create a new Node.js module target. It will create a target with the specified name that is an *interface target*. Those targets are special and only allow certain properties to be set. Those properties, however, will be inherited by the ABI-specific targets, which is what we want here, since it means that you'll only have to modify one target and the respective ABIs are built automatically.

* `NAN_VERSION` (unset by default): Semver of the [Nan](https://github.com/nodejs/nan) abstraction library module. This CMake script will download the headers separately and won't install them as an NPM module. It will only add the Nan headers to the build if this variable is set.
* `MINIMUM_NODE_ABI` (defaults to `46`: Specify the minimum ABI that your module supports. This script will generate targets for all ABIs that are equal or newer to this ABI. The Node.js website has an [overview of all versions and how they map to ABIs](https://nodejs.org/en/download/releases/).
* `INSTALL_PATH` (defaults to `lib/{node_abi}/<name>.node`): The finished node modules will be copied to this path. The path is relative to the directory of the `CMakeLists.txt` file that you call the `add_node_module` function from. Specify `"module_path": "./lib/{node_abi}"` in your `package.json` to have `node-pre-gyp` package the correct folder.
* `CACHE_DIR` (defaults to the value of `NODE_MODULE_CACHE_DIR`): directory where the Node.js and Nan headers are cached to avoid redownloading them. The directory is relative to the directory of the `CMakeLists.txt` file that you call the `add_node_module` function from. By default, they will be stored in the build directory. However, if you have multiple builds (e.g. for different platforms), you can specify a common directory to share them.
* `EXCLUDE_NODE_ABIS`: A list of Node.js ABIs that won't be built. You can use this to exclude old unstable versions (e.g. 5.x = `47`, and 7.x = `51`). See <https://nodejs.org/en/download/releases/> for a list of ABIs (`NODE_MODULE_VERSION`).

This function adds another custom target called `<name>.all` that you can use to request builds for all selected ABIs in your build system scripts.

It sets the variables `<name>::abis`, and `<name>::targets` that contain a list of all selected ABI versions, as well as all generated targets. You can use these variables to iterate over these like this:

```cmake
foreach(ABI IN LISTS targetname::abis)
    # Use ${ABI}    
endforeach()
```
