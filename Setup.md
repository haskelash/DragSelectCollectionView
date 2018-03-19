## Installation

### Cocoapods
Try out the sample project:
````
pod try DragSelectCollectionView
````
Add this as a dependency to your project:
````
pod 'DragSelectCollectionView'
````

## Integration

Make your `UICollectionView` an instance of `DragSelectCollectionView`.
Use it as you would use any other collection view, i.e. with custom data source and delegate objects.
Add a `UILongPressGestureRecognizer` to the collection view.
In the recognizer's called action do the following:
- make sure the recognizer is in the `began` state
- get the index path of the touch point
- call `beginDragSelection(at: path)` on the collection view:

````swift
 @IBAction func longPress(with gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        let point = gr.location(in: collectionView)
        guard let path = collectionView.indexPathForItem(at: point) else { return }
        collectionView.beginDragSelection(at: path)
    }
````
That's it! The collection view will track the touch and select / deselect cells as needed.

If at any point you need to stop the drag selection event, call `touchesEnded`:
````swift
collectionView.touchesEnded([], with: nil)
````
