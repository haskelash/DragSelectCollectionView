# DragSelectCollectionView

[![Build Status][travis-badge]][travis] [![Code Coverage][codecov-badge]][codecov] [![Documentation](https://haskelash.github.io/DragSelectCollectionView/docs/badge.svg)](https://haskelash.github.io/DragSelectCollectionView/docs/index.html)

A `UICollectionView` subclass for selecting multiple cells while dragging.

## Features

Enable selecting collection view cells by dragging along the view | &nbsp; | Auto scroll when the user drags close to the top or bottom of the view | &nbsp; | Set a limit on how many cells can be selected, e.g. a limit of 13
:---------------------------:|--------|:----------------------------:|--------|:---------------------------:
![dragging example](https://haskelash.github.io/DragSelectCollectionView/gifs/dragging.gif) | &nbsp; | ![auto scroll example](https://haskelash.github.io/DragSelectCollectionView/gifs/hotspots.gif) | &nbsp; | ![selection limit example](https://haskelash.github.io/DragSelectCollectionView/gifs/limit.gif)

## Customizations

- Enable / disable auto scroll hotspots.
- Adjust hotspot height and placement.
- Adjust auto scroll speed.
- Prevent certain cells from being drag-selected through the `UICollectionViewDelegate`.

## Documentation

Docs can be found [here](https://haskelash.github.io/DragSelectCollectionView/docs/index.html), generated by [jazzy](https://github.com/realm/jazzy).

## Credits

Inspiration for this project comes from an [Android version](https://github.com/afollestad/drag-select-recyclerview) by [afollestad](https://github.com/afollestad). 

[travis-badge]: https://travis-ci.org/haskelash/DragSelectCollectionView.svg?branch=master
[travis]: https://travis-ci.org/haskelash/DragSelectCollectionView
[codecov-badge]: https://codecov.io/gh/haskelash/DragSelectCollectionView/branch/master/graph/badge.svg
[codecov]: https://codecov.io/gh/haskelash/DragSelectCollectionView
