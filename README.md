PopupView=======![sample image](http://sonson.jp/wp/wp-content/uploads/2011/07/popupViewSample1.png)License=======BSD License.PopupView Initial Image Support=======We've added initial support for skinning a popupview with images to support our needs, amongst other small updates. Its not all completely thought through, but its functional.You'll need a callout box image. This one happens to have a glow around the box, so you can see the transparency around it.![callout box](http://content.screencast.com/users/sprynmr/folders/Jing/media/150535a9-4699-4b1b-9334-8f6c514cd695/00000428.png)In addition you'll need a callout box arrow. The bottom of the arrow shouldn't have any space below it in the image file.![callout arrow](http://content.screencast.com/users/sprynmr/folders/Jing/media/085ff465-4f34-4c83-942d-2bab8eb36387/00000429.png)###UsageYou'll initialize your instance like normal:	popup = [[SNPopupView alloc] initWithString:@"test message" withFontOfSize:16];Now comes the difference. You'll set the box and arrow image:	[popup setBackgroundBoxImage:[UIImage imageNamed:@"callout-box-black.png"] backgroundArrowImage:[UIImage imageNamed:@"callout-arrow-black.png"]];This is just a convenience method for setting those two properties, but it also updates a few other properties added in this update. Here is the content of that method (where self is the popup instance):    self.backgroundBoxImage = backgroundBoxImage;    self.backgroundArrowImage = backgroundArrowImage;    // We don't use the shadow offset when using images    self.shadowOffset = CGSizeZero;    // or the root arrow size, as this is now calculated using the image    self.rootArrowSize = CGSizeZero;Finally there are a couple other properties you'll want to know about. Most important is the ```contentOffset``` property. It used to be hardcoded in the header ```#define CONTENT_OFFSET	CGSizeMake(15, 15)```.Now it's a configurable property, which is important because you'll want to adjust the content offset for any new callout box. So while ```shadowOffset``` isn't used for images, ````contentOffset``` is used to determine the edges of your callout box vs your resizeable inner area.![callout sliced](http://content.screencast.com/users/sprynmr/folders/Jing/media/085ff465-4f34-4c83-942d-2bab8eb36387/00000430.png)	popup.contentOffset = CGSizeMake(15,15);You can also force the direction of the popup, if you don't want it to automatically figure it out:	popup.forceDirection = SNPopupViewUp;Finally is the most confusing, but important property. Its called ```rootArrowOverlap```. Basically this is the distance from the top of the arrow, to the top of the box image (including transparency.) This is required to properly place the y origin of the arrow.For example, in this image I have colored the original background area of the callout box image blue. When I overlay the arrow in the correct place, you can see by the green background that it extends beyond the background of the callout box.![callout alignment](http://content.screencast.com/users/sprynmr/folders/Jing/media/085ff465-4f34-4c83-942d-2bab8eb36387/00000431.png)	popup.rootArrowOverlap = 1; // where 1 is the number of points (not retina pixels, positive or negative) that the arrow edge differs from the callout box's canvasNow in this scenario it would have been easiest to increase the size of the callout box's canvas area. But consider a scenario where your nicely designed box's shadow extends beyond the edge of the arrow. Then you could set this arrow to a negative number to compensate.So in practice, it's easiest to make the arrow image bump up right against the edge of the box's canvas, but this property is there should you need it. (For instance, different sized arrows images with the same callout box image.)SNPopupView Reference=======	- (id)initWithString:(NSString*)newValue;###Parameters####newValueThre string to display as title in the popup.###Return valueAn initialized popup.###DiscussionThis method uses default title's font size. If you want to set own font size for title, you should use initWithString:withFontOfSize:.	- (id)initWithString:(NSString*)newValue withFontOfSize:(float)newFontSize;###Parameters####newValueThre string to display as title in the popup.####newFontSizeThe point size of the font for title.###Return valueAn initialized popup.###DiscussionThis method does not automatically adjust font size of title. Therefore, the title string can go over popup view if you specfy too big font size.		- (id)initWithImage:(UIImage*)newImage;###Parameters####newImageThe image to display in the popup.###Return valueAn initialized popup.###DiscussionNone.	- (id)initWithContentView:(UIView*)newContentView contentSize:(CGSize)contentSize;###Parameters####newContentViewThe new view whose content should be displayed by popup.####contentSizeThe new size to apply to the content view.###Return valueAn initialized popup.###DiscussionNone.	- (void)showAtPoint:(CGPoint)p inView:(UIView*)inView;###Parameters####pThe position to display popup withing the coordinate system of popup's superview, that is inView. Popup anchors at this point.####inViewThe view to set as popup' superview.###DiscussionNone.	- (void)showAtPoint:(CGPoint)p inView:(UIView*)inView animated:(BOOL)animated;###Parameters####pThe position to display popup withing the coordinate system of popup's superview, that is inView. Popup anchors at this point.####inViewThe view to contain popup.####animatedSpecify YES to show it with animation, NO to show it immediately.###DiscussionNone.		- (void)dismiss;###DiscussionDismiss popup with animation.	- (void)dismiss:(BOOL)animtaed;###Parameters####animatedSpecify YES to dimiss it with animation, NO to dimiss it immediately.###DiscussionNone.	- (void)addTarget:(id)target action:(SEL)action;###Prameters####targetThe target object-that is, the object to which the action message is sent. If this is nil, the responder chain is searched for an object willing to respond to the action message.####actionA selector identifying an action message. It cannot be NULL.###DiscussionSNPopupView Reference - Using Private Method Addition.=======	- (void)showFromBarButtonItem:(UIBarButtonItem*)barButtonItem inView:(UIView*)inView;###Parameters####barButtonItemThe bar button item on which to anchor the popup.####inViewThe view to contain popup.###DiscussionThis method uses a private method of UIBarButtonItem. Take care when submit your applicaiton that uses this method.	- (void)showFromBarButtonItem:(UIBarButtonItem*)barButtonItem inView:(UIView*)inView animated:(BOOL)animated;###Parameters####barButtonItemThe bar button item on which to anchor the popup.####inViewThe view to contain popup.####animatedSpecify YES to show it with animation, NO to show it immediately.###DiscussionThis method uses a private method of UIBarButtonItem. Take care when submit your applicaiton that uses this method.Properties======###titleThe receiver's title string value.	@property(nonatomic, readonly) NSString *title;###DiscussionNone.###imageThe receiver's image value.	@property(nonatomic, readonly) UIImage *image;###DiscussionNone.###contentViewThe receiver's content view.	@property(nonatomic, readonly) UIView *contentView;###DiscussionBlog======= * [sonson.jp][]Sorry, Japanese only....Dependency======= * none[sonson.jp]: http://sonson.jp