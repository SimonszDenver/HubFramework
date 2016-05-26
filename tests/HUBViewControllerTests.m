#import <XCTest/XCTest.h>

#import "HUBViewControllerImplementation.h"
#import "HUBViewModelLoaderImplementation.h"
#import "HUBContentOperationMock.h"
#import "HUBComponentRegistryImplementation.h"
#import "HUBComponentIdentifier.h"
#import "HUBJSONSchemaImplementation.h"
#import "HUBConnectivityStateResolverMock.h"
#import "HUBImageLoaderMock.h"
#import "HUBViewModelBuilder.h"
#import "HUBComponentModelBuilder.h"
#import "HUBComponentModel.h"
#import "HUBComponentImageDataBuilder.h"
#import "HUBComponentFactoryMock.h"
#import "HUBComponentMock.h"
#import "HUBCollectionViewFactoryMock.h"
#import "HUBCollectionViewMock.h"
#import "HUBComponentLayoutManagerMock.h"
#import "HUBInitialViewModelRegistry.h"
#import "HUBViewModel.h"
#import "HUBContentReloadPolicyMock.h"
#import "HUBComponentDefaults+Testing.h"
#import "HUBComponentFallbackHandlerMock.h"
#import "HUBIconImageResolverMock.h"
#import "HUBDeviceMock.h"
#import "HUBUtilities.h"
#import "HUBFeatureInfoImplementation.h"

@interface HUBViewControllerTests : XCTestCase <HUBViewControllerDelegate>

@property (nonatomic, strong) HUBContentOperationMock *contentOperation;
@property (nonatomic, strong) HUBContentReloadPolicyMock *contentReloadPolicy;
@property (nonatomic, strong) HUBComponentIdentifier *componentIdentifier;
@property (nonatomic, strong) HUBComponentMock *component;
@property (nonatomic, strong) HUBCollectionViewMock *collectionView;
@property (nonatomic, strong) HUBCollectionViewFactoryMock *collectionViewFactory;
@property (nonatomic, strong) HUBComponentRegistryImplementation *componentRegistry;
@property (nonatomic, strong) HUBViewModelLoaderImplementation *viewModelLoader;
@property (nonatomic, strong) HUBImageLoaderMock *imageLoader;
@property (nonatomic, strong) HUBInitialViewModelRegistry *initialViewModelRegistry;
@property (nonatomic, strong) HUBDeviceMock *device;
@property (nonatomic, strong) HUBViewControllerImplementation *viewController;
@property (nonatomic, strong) id<HUBViewModel> viewModelFromDelegateMethod;
@property (nonatomic, strong) NSMutableArray<id<HUBComponentModel>> *componentModelsFromAppearanceDelegateMethod;
@property (nonatomic, strong) NSMutableArray<id<HUBComponentModel>> *componentModelsFromDisapperanceDelegateMethod;
@property (nonatomic, strong) NSMutableArray<id<HUBComponentModel>> *componentModelsFromSelectionDelegateMethod;

@end

@implementation HUBViewControllerTests

#pragma mark - XCTestCase

- (void)setUp
{
    [super setUp];
    
    HUBComponentDefaults * const componentDefaults = [HUBComponentDefaults defaultsForTesting];
    id<HUBComponentFallbackHandler> const componentFallbackHandler = [[HUBComponentFallbackHandlerMock alloc] initWithComponentDefaults:componentDefaults];
    id<HUBIconImageResolver> const iconImageResolver = [HUBIconImageResolverMock new];
    
    self.contentOperation = [HUBContentOperationMock new];
    self.contentReloadPolicy = [HUBContentReloadPolicyMock new];
    self.componentIdentifier = [[HUBComponentIdentifier alloc] initWithNamespace:componentDefaults.componentNamespace name:componentDefaults.componentName];
    self.componentRegistry = [[HUBComponentRegistryImplementation alloc] initWithFallbackHandler:componentFallbackHandler];
    self.component = [HUBComponentMock new];
    
    self.collectionView = [HUBCollectionViewMock new];
    self.collectionViewFactory = [[HUBCollectionViewFactoryMock alloc] initWithCollectionView:self.collectionView];
    
    id<HUBComponentFactory> const componentFactory = [[HUBComponentFactoryMock alloc] initWithComponents:@{componentDefaults.componentName: self.component}];
    [self.componentRegistry registerComponentFactory:componentFactory forNamespace:componentDefaults.componentNamespace];
    
    NSURL * const viewURI = [NSURL URLWithString:@"spotify:hub:framework"];
    HUBFeatureInfoImplementation * const featureInfo = [[HUBFeatureInfoImplementation alloc] initWithIdentifier:@"id" title:@"title"];
    
    id<HUBJSONSchema> const JSONSchema = [[HUBJSONSchemaImplementation alloc] initWithComponentDefaults:componentDefaults iconImageResolver:iconImageResolver];
    id<HUBConnectivityStateResolver> const connectivityStateResolver = [HUBConnectivityStateResolverMock new];
    
    self.viewModelLoader = [[HUBViewModelLoaderImplementation alloc] initWithViewURI:viewURI
                                                                         featureInfo:featureInfo
                                                                   contentOperations:@[self.contentOperation]
                                                                          JSONSchema:JSONSchema
                                                                   componentDefaults:componentDefaults
                                                           connectivityStateResolver:connectivityStateResolver
                                                                   iconImageResolver:iconImageResolver
                                                                    initialViewModel:nil];
    
    self.imageLoader = [HUBImageLoaderMock new];
    
    id<HUBComponentLayoutManager> const componentLayoutManager = [HUBComponentLayoutManagerMock new];
    
    self.initialViewModelRegistry = [HUBInitialViewModelRegistry new];
    self.device = [HUBDeviceMock new];
    
    self.viewController = [[HUBViewControllerImplementation alloc] initWithViewURI:viewURI
                                                                   viewModelLoader:self.viewModelLoader
                                                             collectionViewFactory:self.collectionViewFactory
                                                                 componentRegistry:self.componentRegistry
                                                            componentLayoutManager:componentLayoutManager
                                                          initialViewModelRegistry:self.initialViewModelRegistry
                                                                            device:self.device
                                                               contentReloadPolicy:self.contentReloadPolicy
                                                                       imageLoader:self.imageLoader];
    
    self.viewController.delegate = self;
    
    self.viewModelFromDelegateMethod = nil;
    self.componentModelsFromAppearanceDelegateMethod = [NSMutableArray new];
    self.componentModelsFromDisapperanceDelegateMethod = [NSMutableArray new];
    self.componentModelsFromSelectionDelegateMethod = [NSMutableArray new];
}

#pragma mark - Tests

- (void)testContentLoadedOnViewWillAppear
{
    __block BOOL contentLoaded = NO;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> builder) {
        contentLoaded = YES;
        return YES;
    };
    
    [self.viewController viewWillAppear:YES];
    
    XCTAssertTrue(contentLoaded);
}

- (void)testDelegateNotifiedOfUpdatedViewModel
{
    NSString * const viewModelNavBarTitleA = @"View model A";
    NSString * const viewModelNavBarTitleB = @"View model B";
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> builder) {
        builder.navigationBarTitle = viewModelNavBarTitleA;
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    XCTAssertEqualObjects(self.viewModelFromDelegateMethod.navigationBarTitle, viewModelNavBarTitleA);
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> builder) {
        builder.navigationBarTitle = viewModelNavBarTitleB;
        return YES;
    };
    
    self.contentReloadPolicy.shouldReload = YES;
    [self.viewController viewWillAppear:YES];
    
    XCTAssertEqualObjects(self.viewModelFromDelegateMethod.navigationBarTitle, viewModelNavBarTitleB);
}

- (void)testReloadPolicyPreventingReload
{
    NSString * const viewModelNavBarTitleA = @"View model A";
    NSString * const viewModelNavBarTitleB = @"View model B";
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> builder) {
        builder.navigationBarTitle = viewModelNavBarTitleA;
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    XCTAssertEqualObjects(self.viewModelFromDelegateMethod.navigationBarTitle, viewModelNavBarTitleA);
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> builder) {
        builder.navigationBarTitle = viewModelNavBarTitleB;
        return YES;
    };
    
    self.contentReloadPolicy.shouldReload = NO;
    [self.viewController viewWillAppear:YES];
    
    XCTAssertEqualObjects(self.viewModelFromDelegateMethod.navigationBarTitle, viewModelNavBarTitleA);
}

- (void)testNilReloadPolicyAlwaysResultingInReload
{
    NSURL * const viewURI = [NSURL URLWithString:@"spotify:hub:framework"];
    id<HUBComponentLayoutManager> const componentLayoutManager = [HUBComponentLayoutManagerMock new];
    
    self.viewController = [[HUBViewControllerImplementation alloc] initWithViewURI:viewURI
                                                                   viewModelLoader:self.viewModelLoader
                                                             collectionViewFactory:self.collectionViewFactory
                                                                 componentRegistry:self.componentRegistry
                                                            componentLayoutManager:componentLayoutManager
                                                          initialViewModelRegistry:self.initialViewModelRegistry
                                                                            device:self.device
                                                               contentReloadPolicy:nil
                                                                       imageLoader:self.imageLoader];
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> builder) {
        builder.navigationBarTitle = @"Hub Framework";
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    XCTAssertEqual(self.contentOperation.performCount, (NSUInteger)1);
    
    [self.viewController viewWillAppear:NO];
    [self.viewController viewWillAppear:NO];
    [self.viewController viewWillAppear:NO];
    [self.viewController viewWillAppear:NO];
    
    XCTAssertEqual(self.contentOperation.performCount, (NSUInteger)5);
}

- (void)testHeaderComponentImageLoading
{
    NSURL * const mainImageURL = [NSURL URLWithString:@"https://image.main"];
    NSURL * const backgroundImageURL = [NSURL URLWithString:@"https://image.background"];
    NSURL * const customImageURL = [NSURL URLWithString:@"https://image.custom"];
    NSString * const customImageIdentifier = @"custom";
    
    __weak __typeof(self) weakSelf = self;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> builder) {
        __typeof(self) strongSelf = weakSelf;
        
        builder.headerComponentModelBuilder.componentName = strongSelf.componentIdentifier.componentName;
        builder.headerComponentModelBuilder.mainImageDataBuilder.URL = mainImageURL;
        builder.headerComponentModelBuilder.backgroundImageDataBuilder.URL = backgroundImageURL;
        [builder.headerComponentModelBuilder builderForCustomImageDataWithIdentifier:customImageIdentifier].URL = customImageURL;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    [self performAsynchronousTestWithBlock:^{
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:mainImageURL]);
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:backgroundImageURL]);
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:customImageURL]);
    }];
}

- (void)testBodyComponentImageLoading
{
    NSURL * const mainImageURL = [NSURL URLWithString:@"https://image.main"];
    NSURL * const backgroundImageURL = [NSURL URLWithString:@"https://image.background"];
    NSURL * const customImageURL = [NSURL URLWithString:@"https://image.custom"];
    NSString * const customImageIdentifier = @"custom";
    
    __weak __typeof(self) weakSelf = self;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        __typeof(self) strongSelf = weakSelf;
        
        id<HUBComponentModelBuilder> const componentModelBuilder = [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"component"];
        componentModelBuilder.componentName = strongSelf.componentIdentifier.componentName;
        componentModelBuilder.mainImageDataBuilder.URL = mainImageURL;
        componentModelBuilder.backgroundImageDataBuilder.URL = backgroundImageURL;
        [componentModelBuilder builderForCustomImageDataWithIdentifier:customImageIdentifier].URL = customImageURL;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    
    [self performAsynchronousTestWithBlock:^{
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:mainImageURL]);
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:backgroundImageURL]);
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:customImageURL]);
    }];
}

- (void)testOverlayComponentImageLoading
{
    NSURL * const mainImageURL = [NSURL URLWithString:@"https://image.main"];
    NSURL * const backgroundImageURL = [NSURL URLWithString:@"https://image.background"];
    NSURL * const customImageURL = [NSURL URLWithString:@"https://image.custom"];
    NSString * const customImageIdentifier = @"custom";
    
    __weak __typeof(self) weakSelf = self;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> builder) {
        __typeof(self) strongSelf = weakSelf;
        
        id<HUBComponentModelBuilder> const overlayComponentModelBuilder = [builder builderForOverlayComponentModelWithIdentifier:@"overlay"];
        
        overlayComponentModelBuilder.componentNamespace = strongSelf.componentIdentifier.componentNamespace;
        overlayComponentModelBuilder.componentName = strongSelf.componentIdentifier.componentName;
        overlayComponentModelBuilder.mainImageDataBuilder.URL = mainImageURL;
        overlayComponentModelBuilder.backgroundImageDataBuilder.URL = backgroundImageURL;
        [overlayComponentModelBuilder builderForCustomImageDataWithIdentifier:customImageIdentifier].URL = customImageURL;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    [self performAsynchronousTestWithBlock:^{
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:mainImageURL]);
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:backgroundImageURL]);
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:customImageURL]);
    }];
}

- (void)testMissingImageLoadingContextHandled
{
    NSURL * const imageURL = [NSURL URLWithString:@"http://image.com"];
    [self.imageLoader.delegate imageLoader:self.imageLoader didLoadImage:[UIImage new] forURL:imageURL fromCache:NO];
}

- (void)testImageLoadingForMultipleComponentsSharingTheSameImageURL
{
    NSURL * const imageURL = [NSURL URLWithString:@"https://image.url"];
    
    NSString * const componentNamespace = @"sameImage";
    NSString * const componentNameA = @"componentA";
    NSString * const componentNameB = @"componentB";
    HUBComponentMock * const componentA = [HUBComponentMock new];
    HUBComponentMock * const componentB = [HUBComponentMock new];
    
    HUBComponentFactoryMock * const componentFactory = [[HUBComponentFactoryMock alloc] initWithComponents:@{
        componentNameA: componentA,
        componentNameB: componentB
    }];
    
    [self.componentRegistry registerComponentFactory:componentFactory forNamespace:componentNamespace];
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        id<HUBComponentModelBuilder> const componentModelBuilderA = [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"componentA"];
        componentModelBuilderA.componentNamespace = componentNamespace;
        componentModelBuilderA.componentName = componentNameA;
        componentModelBuilderA.mainImageDataBuilder.URL = imageURL;
        
        id<HUBComponentModelBuilder> const componentModelBuilderB = [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"componentB"];
        componentModelBuilderB.componentNamespace = componentNamespace;
        componentModelBuilderB.componentName = componentNameB;
        componentModelBuilderB.mainImageDataBuilder.URL = imageURL;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    id<UICollectionViewDataSource> const collectionViewDataSource = self.collectionView.dataSource;
    
    NSIndexPath * const indexPathA = [NSIndexPath indexPathForItem:0 inSection:0];
    NSIndexPath * const indexPathB = [NSIndexPath indexPathForItem:1 inSection:0];
    
    self.collectionView.cells[indexPathA] = [collectionViewDataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPathA];
    self.collectionView.cells[indexPathB] = [collectionViewDataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPathB];
    
    [self.imageLoader.delegate imageLoader:self.imageLoader didLoadImage:[UIImage new] forURL:imageURL fromCache:NO];
    
    XCTAssertEqualObjects(componentA.mainImageData.URL, imageURL);
    XCTAssertEqualObjects(componentB.mainImageData.URL, imageURL);
}

- (void)testImageLoadingForChildComponent
{
    NSURL * const mainImageURL = [NSURL URLWithString:@"https://image.main"];
    NSURL * const backgroundImageURL = [NSURL URLWithString:@"https://image.background"];
    NSURL * const customImageURL = [NSURL URLWithString:@"https://image.custom"];
    NSString * const customImageIdentifier = @"custom";
    
    NSString * const componentNamespace = @"childComponentImageLoading";
    NSString * const componentName = @"component";
    NSString * const childComponentName = @"componentB";
    HUBComponentMock * const component = [HUBComponentMock new];
    HUBComponentMock * const childComponent = [HUBComponentMock new];
    
    HUBComponentFactoryMock * const componentFactory = [[HUBComponentFactoryMock alloc] initWithComponents:@{
        componentName: component,
        childComponentName: childComponent
    }];
    
    [self.componentRegistry registerComponentFactory:componentFactory forNamespace:componentNamespace];
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        id<HUBComponentModelBuilder> const componentModelBuilder = [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"component"];
        componentModelBuilder.componentNamespace = componentNamespace;
        componentModelBuilder.componentName = componentName;
        
        id<HUBComponentModelBuilder> const childComponentModelBuilder = [componentModelBuilder builderForChildComponentModelWithIdentifier:@"child"];
        childComponentModelBuilder.componentNamespace = componentNamespace;
        childComponentModelBuilder.componentName = childComponentName;
        childComponentModelBuilder.mainImageDataBuilder.URL = mainImageURL;
        childComponentModelBuilder.backgroundImageDataBuilder.URL = backgroundImageURL;
        [childComponentModelBuilder builderForCustomImageDataWithIdentifier:customImageIdentifier].URL = customImageURL;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    [component.childDelegate component:component willDisplayChildAtIndex:0 view:[UIView new]];
    
    [self performAsynchronousTestWithBlock:^{
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:mainImageURL]);
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:backgroundImageURL]);
        XCTAssertTrue([self.imageLoader hasLoadedImageForURL:customImageURL]);
    }];
}

- (void)testNoImagesLoadedIfComponentDoesNotHandleImages
{
    self.component.canHandleImages = NO;
    
    NSURL * const mainImageURL = [NSURL URLWithString:@"https://image.main"];
    __weak __typeof(self) weakSelf = self;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        __typeof(self) strongSelf = weakSelf;
        
        id<HUBComponentModelBuilder> const componentModelBuilder = [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"component"];
        componentModelBuilder.componentName = strongSelf.componentIdentifier.componentName;
        componentModelBuilder.mainImageDataBuilder.URL = mainImageURL;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    
    XCTAssertFalse([self.imageLoader hasLoadedImageForURL:mainImageURL]);
}

- (void)testHeaderComponentReuse
{
    __weak __typeof(self) weakSelf = self;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        __typeof(self) strongSelf = weakSelf;
        viewModelBuilder.headerComponentModelBuilder.componentName = strongSelf.componentIdentifier.componentName;
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    XCTAssertEqual(self.component.numberOfReuses, (NSUInteger)0);
    
    self.contentReloadPolicy.shouldReload = YES;
    
    [self.viewController viewWillAppear:YES];
    [self.viewController viewDidLayoutSubviews];
    [self.viewController viewWillAppear:YES];
    [self.viewController viewDidLayoutSubviews];
    
    XCTAssertEqual(self.component.numberOfReuses, (NSUInteger)2);
}

- (void)testHeaderComponentNotifiedOfViewWillAppear
{
    self.component.isViewObserver = YES;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        viewModelBuilder.headerComponentModelBuilder.title = @"Header";
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    XCTAssertEqual(self.component.numberOfAppearances, (NSUInteger)1);
    
    [self.viewController viewWillAppear:YES];
    [self.viewController viewWillAppear:YES];
    
    XCTAssertEqual(self.component.numberOfAppearances, (NSUInteger)3);
}

- (void)testOverlayComponentReuse
{
    HUBComponentMock * const componentA = [HUBComponentMock new];
    HUBComponentMock * const componentB = [HUBComponentMock new];
    
    id<HUBComponentFactory> const componentFactory = [[HUBComponentFactoryMock alloc] initWithComponents:@{
        @"a": componentA,
        @"b": componentB
    }];
    
    NSString * const componentNamespace = @"overlayReuse";
    [self.componentRegistry registerComponentFactory:componentFactory forNamespace:componentNamespace];
    
    __block NSUInteger loadCount = 0;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        id<HUBComponentModelBuilder> const overlayComponentModelBuilder = [viewModelBuilder builderForOverlayComponentModelWithIdentifier:@"overlay"];
        overlayComponentModelBuilder.componentNamespace = componentNamespace;
        
        if (loadCount < 3) {
            overlayComponentModelBuilder.componentName = @"a";
        } else {
            overlayComponentModelBuilder.componentName = @"b";
        }
        
        loadCount++;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    XCTAssertEqual(componentA.numberOfReuses, (NSUInteger)0);
    XCTAssertEqual(componentB.numberOfReuses, (NSUInteger)0);
    
    self.contentReloadPolicy.shouldReload = YES;
    
    [self.viewController viewWillAppear:YES];
    [self.viewController viewDidLayoutSubviews];
    [self.viewController viewWillAppear:YES];
    [self.viewController viewDidLayoutSubviews];
    
    XCTAssertEqual(componentA.numberOfReuses, (NSUInteger)2);
    XCTAssertEqual(componentB.numberOfReuses, (NSUInteger)0);
    
    [self.viewController viewWillAppear:YES];
    [self.viewController viewDidLayoutSubviews];
    [self.viewController viewWillAppear:YES];
    [self.viewController viewDidLayoutSubviews];
    
    XCTAssertEqual(componentA.numberOfReuses, (NSUInteger)2);
    XCTAssertEqual(componentB.numberOfReuses, (NSUInteger)1);
}

- (void)testOverlayComponentsNotifiedOfViewWillAppear
{
    self.component.isViewObserver = YES;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        [viewModelBuilder builderForOverlayComponentModelWithIdentifier:@"overlay"].title = @"Header";
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    XCTAssertEqual(self.component.numberOfAppearances, (NSUInteger)1);
    
    [self.viewController viewWillAppear:YES];
    [self.viewController viewWillAppear:YES];
    
    XCTAssertEqual(self.component.numberOfAppearances, (NSUInteger)3);
}

- (void)testInitialViewModelForTargetViewControllerRegistered
{
    __weak __typeof(self) weakSelf = self;
    
    NSString * const initialViewModelIdentifier = @"initialViewModel";
    NSURL * const targetViewURI = [NSURL URLWithString:@"spotify:hub:target"];
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        id<HUBComponentModelBuilder> const componentModelBuilder = [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"id"];
        componentModelBuilder.componentName = weakSelf.componentIdentifier.componentName;
        componentModelBuilder.targetURL = targetViewURI;
        componentModelBuilder.targetInitialViewModelBuilder.viewIdentifier = initialViewModelIdentifier;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView.delegate collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
    
    id<HUBViewModel> const targetInitialViewModel = [self.initialViewModelRegistry initialViewModelForViewURI:targetViewURI];
    XCTAssertEqualObjects(targetInitialViewModel.identifier, initialViewModelIdentifier);
}

- (void)testComponentDeselectedOnViewWillDisappear
{
    __weak __typeof(self) weakSelf = self;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        __typeof(self) strongSelf = weakSelf;
        
        id<HUBComponentModelBuilder> const componentModelBuilder = [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"component"];
        componentModelBuilder.componentName = strongSelf.componentIdentifier.componentName;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    
    XCTAssertEqualObjects(self.collectionView.selectedIndexPaths, [NSSet setWithObject:indexPath]);
    
    [self.viewController viewWillDisappear:NO];
    
    XCTAssertEqual(self.collectionView.selectedIndexPaths.count, (NSUInteger)0);
}

- (void)testCreatingChildComponent
{
    NSString * const componentNamespace = @"childComponentSelection";
    NSString * const componentName = @"component";
    NSString * const childComponentName = @"componentB";
    HUBComponentMock * const component = [HUBComponentMock new];
    HUBComponentMock * const childComponent = [HUBComponentMock new];
    childComponent.preferredViewSize = CGSizeMake(100, 200);
    
    HUBComponentFactoryMock * const componentFactory = [[HUBComponentFactoryMock alloc] initWithComponents:@{
        componentName: component,
        childComponentName: childComponent
    }];
    
    [self.componentRegistry registerComponentFactory:componentFactory forNamespace:componentNamespace];
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        id<HUBComponentModelBuilder> const componentModelBuilder = [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"component"];
        componentModelBuilder.componentNamespace = componentNamespace;
        componentModelBuilder.componentName = componentName;
        
        id<HUBComponentModelBuilder> const childComponentModelBuilder = [componentModelBuilder builderForChildComponentModelWithIdentifier:@"child"];
        childComponentModelBuilder.componentNamespace = componentNamespace;
        childComponentModelBuilder.componentName = childComponentName;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    
    id<HUBComponentChildDelegate> const childDelegate = component.childDelegate;
    
    XCTAssertEqual([childDelegate component:component createChildComponentAtIndex:0], childComponent);
    XCTAssertTrue(CGSizeEqualToSize(childComponent.view.frame.size, childComponent.preferredViewSize));
    
    XCTAssertNil([childDelegate component:component createChildComponentAtIndex:5]);
}

- (void)testSelectionForRootComponent
{
    NSString * const componentNamespace = @"selectionForRootComponent";
    NSString * const nonSelectableIdentifier = @"nonSelectable";
    NSString * const selectableIdentifier = @"selectable";
    
    HUBComponentMock * const nonSelectableComponent = [HUBComponentMock new];
    HUBComponentMock * const selectableComponent = [HUBComponentMock new];
    
    HUBComponentFactoryMock * const componentFactory = [[HUBComponentFactoryMock alloc] initWithComponents:@{
        nonSelectableIdentifier: nonSelectableComponent,
        selectableIdentifier: selectableComponent
    }];
    
    [self.componentRegistry registerComponentFactory:componentFactory forNamespace:componentNamespace];
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        id<HUBComponentModelBuilder> const nonSelectableBuilder = [viewModelBuilder builderForBodyComponentModelWithIdentifier:nonSelectableIdentifier];
        nonSelectableBuilder.componentNamespace = componentNamespace;
        nonSelectableBuilder.componentName = nonSelectableIdentifier;
        
        id<HUBComponentModelBuilder> const selectableBuilder = [viewModelBuilder builderForBodyComponentModelWithIdentifier:selectableIdentifier];
        selectableBuilder.componentNamespace = componentNamespace;
        selectableBuilder.componentName = selectableIdentifier;
        selectableBuilder.targetURL = [NSURL URLWithString:@"spotify:hub:framework"];
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    id<UICollectionViewDelegate> const collectionViewDelegate = self.collectionView.delegate;
    
    NSIndexPath * const nonSelectableIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [collectionViewDelegate collectionView:self.collectionView didSelectItemAtIndexPath:nonSelectableIndexPath];
    XCTAssertEqual(self.componentModelsFromSelectionDelegateMethod.count, (NSUInteger)0);
    
    NSIndexPath * const selectableIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];
    [collectionViewDelegate collectionView:self.collectionView didSelectItemAtIndexPath:selectableIndexPath];
    XCTAssertEqual(self.componentModelsFromSelectionDelegateMethod.count, (NSUInteger)1);
    XCTAssertEqualObjects(self.componentModelsFromSelectionDelegateMethod[0].targetURL, [NSURL URLWithString:@"spotify:hub:framework"]);
}

- (void)testSelectionForChildComponent
{
    NSString * const componentNamespace = @"childComponentSelection";
    NSString * const componentName = @"component";
    NSString * const childComponentName = @"componentB";
    NSURL * const childComponentTargetURL = [NSURL URLWithString:@"spotify:hub:child-component"];
    NSString * const childComponentInitialViewModelIdentifier = @"viewModel";
    HUBComponentMock * const component = [HUBComponentMock new];
    HUBComponentMock * const childComponent = [HUBComponentMock new];
    
    HUBComponentFactoryMock * const componentFactory = [[HUBComponentFactoryMock alloc] initWithComponents:@{
        componentName: component,
        childComponentName: childComponent
    }];
    
    [self.componentRegistry registerComponentFactory:componentFactory forNamespace:componentNamespace];
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        id<HUBComponentModelBuilder> const componentModelBuilder = [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"component"];
        componentModelBuilder.componentNamespace = componentNamespace;
        componentModelBuilder.componentName = componentName;
        
        id<HUBComponentModelBuilder> const childComponentModelBuilder = [componentModelBuilder builderForChildComponentModelWithIdentifier:@"child"];
        childComponentModelBuilder.componentNamespace = componentNamespace;
        childComponentModelBuilder.componentName = childComponentName;
        childComponentModelBuilder.targetURL = childComponentTargetURL;
        childComponentModelBuilder.targetInitialViewModelBuilder.viewIdentifier = childComponentInitialViewModelIdentifier;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    
    id<HUBComponentChildDelegate> const childDelegate = component.childDelegate;
    [childDelegate component:component childSelectedAtIndex:0 view:[UIView new]];
    
    id<HUBViewModel> const childComponentTargetInitialViewModel = [self.initialViewModelRegistry initialViewModelForViewURI:childComponentTargetURL];
    XCTAssertEqualObjects(childComponentTargetInitialViewModel.identifier, childComponentInitialViewModelIdentifier);
    
    // Make sure bounds-checking is performed for child component index
    [childDelegate component:component willDisplayChildAtIndex:99 view:[UIView new]];
    
    XCTAssertEqual(self.componentModelsFromSelectionDelegateMethod.count, (NSUInteger)1);
    XCTAssertEqualObjects(self.componentModelsFromSelectionDelegateMethod[0].targetURL, childComponentTargetURL);
}

- (void)testComponentNotifiedOfResize
{
    self.component.isViewObserver = YES;
    
    __weak __typeof(self) weakSelf = self;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        __typeof(self) strongSelf = weakSelf;
        id<HUBComponentModelBuilder> const componentModelBuilder = [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"component"];
        componentModelBuilder.componentName = strongSelf.componentIdentifier.componentName;
        
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    UICollectionViewCell * const cell = [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    cell.frame = CGRectMake(0, 0, 300, 200);
    [cell layoutSubviews];
    XCTAssertEqual(self.component.numberOfResizes, (NSUInteger)1);
    
    // Subsequent layout passes should not notify the component, unless the size has changed
    [cell layoutSubviews];
    [cell layoutSubviews];
    [cell layoutSubviews];
    XCTAssertEqual(self.component.numberOfResizes, (NSUInteger)1);
    
    cell.frame = CGRectMake(0, 0, 300, 100);
    [cell layoutSubviews];
    XCTAssertEqual(self.component.numberOfResizes, (NSUInteger)2);
}

- (void)testComponentNotifiedOfViewWillAppearOnCellCreationOnSystemVersion7
{
    self.device.mockedSystemVersion = @"7.0.0";
    self.component.isViewObserver = YES;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"component"].title = @"A title";
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    
    XCTAssertEqual(self.component.numberOfAppearances, (NSUInteger)1);
}

- (void)testComponentNotifiedOfViewWillAppearWhenCellIsDisplayed
{
    self.device.mockedSystemVersion = @"8.0.0";
    self.component.isViewObserver = YES;
    
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"component"].title = @"title";
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    UICollectionViewCell * const cell = [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    self.collectionView.cells[indexPath] = cell;
    
HUB_IGNORE_PARTIAL_AVAILABILTY_BEGIN
    [self.collectionView.delegate collectionView:self.collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
HUB_IGNORE_PARTIAL_AVAILABILTY_END
    
    XCTAssertEqual(self.component.numberOfAppearances, (NSUInteger)1);
    XCTAssertEqual(self.componentModelsFromAppearanceDelegateMethod.count, (NSUInteger)1);
    XCTAssertEqualObjects(self.componentModelsFromAppearanceDelegateMethod[0].title, @"title");
    
    self.collectionView.mockedIndexPathsForVisibleItems = @[indexPath];
    [self.viewController viewWillAppear:NO];
    
    XCTAssertEqual(self.component.numberOfAppearances, (NSUInteger)2);
    XCTAssertEqual(self.componentModelsFromAppearanceDelegateMethod.count, (NSUInteger)2);
    XCTAssertEqualObjects(self.componentModelsFromAppearanceDelegateMethod[1].title, @"title");
}

- (void)testDelegateNotifiedWhenRootComponentDisappeared
{
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"component"].title = @"Title";
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    UICollectionViewCell * const cell = [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    [self.collectionView.delegate collectionView:self.collectionView didEndDisplayingCell:cell forItemAtIndexPath:indexPath];
    
    XCTAssertEqual(self.componentModelsFromDisapperanceDelegateMethod.count, (NSUInteger)1);
    XCTAssertEqualObjects(self.componentModelsFromDisapperanceDelegateMethod[0].title, @"Title");
}

- (void)testDelegateNotifiedWhenChildComponentDisappeared
{
    self.contentOperation.contentLoadingBlock = ^(id<HUBViewModelBuilder> viewModelBuilder) {
        id<HUBComponentModelBuilder> const componentModelBuilder = [viewModelBuilder builderForBodyComponentModelWithIdentifier:@"component"];
        componentModelBuilder.title = @"Title";
        [componentModelBuilder builderForChildComponentModelWithIdentifier:@"child"].title = @"Child title";
        return YES;
    };
    
    [self simulateViewControllerLayoutCycle];
    NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    [self.component.childDelegate component:self.component didStopDisplayingChildAtIndex:0 view:[UIView new]];
    
    XCTAssertEqual(self.componentModelsFromDisapperanceDelegateMethod.count, (NSUInteger)1);
    XCTAssertEqualObjects(self.componentModelsFromDisapperanceDelegateMethod[0].title, @"Child title");
    
}

- (void)testSettingBackgroundColorOfViewAlsoUpdatesCollectionView
{
    self.viewController.view.backgroundColor = [UIColor redColor];
    XCTAssertEqualObjects(self.collectionView.backgroundColor, [UIColor redColor]);
}

#pragma mark - HUBViewControllerDelegate

- (void)viewController:(UIViewController<HUBViewController> *)viewController didUpdateWithViewModel:(id<HUBViewModel>)viewModel
{
    XCTAssertEqual(viewController, self.viewController);
    self.viewModelFromDelegateMethod = viewModel;
}

- (void)viewController:(UIViewController<HUBViewController> *)viewController
    componentWithModel:(id<HUBComponentModel>)componentModel
      willAppearInView:(UIView *)componentView
{
    XCTAssertEqual(viewController, self.viewController);
    [self.componentModelsFromAppearanceDelegateMethod addObject:componentModel];
}

- (void)viewController:(UIViewController<HUBViewController> *)viewController
    componentWithModel:(id<HUBComponentModel>)componentModel
  didDisappearFromView:(UIView *)componentView
{
    XCTAssertEqual(viewController, self.viewController);
    [self.componentModelsFromDisapperanceDelegateMethod addObject:componentModel];
}

- (void)viewController:(UIViewController<HUBViewController> *)viewController
    componentWithModel:(id<HUBComponentModel>)componentModel
        selectedInView:(UIView *)componentView
{
    XCTAssertEqual(viewController, self.viewController);
    [self.componentModelsFromSelectionDelegateMethod addObject:componentModel];
}

#pragma mark - Utilities

- (void)simulateViewControllerLayoutCycle
{
    [self.viewController loadView];
    [self.viewController viewDidLoad];
    [self.viewController viewWillAppear:YES];
    self.viewController.view.frame = CGRectMake(0, 0, 320, 400);
    [self.viewController viewDidLayoutSubviews];
}

- (void)performAsynchronousTestWithBlock:(void(^)(void))block
{
    XCTestExpectation * const expectation = [self expectationWithDescription:@"Async test"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        block();
    }];
}

@end
