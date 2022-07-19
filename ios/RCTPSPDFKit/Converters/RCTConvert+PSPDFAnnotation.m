//
//  Copyright © 2018-2022 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import "RCTConvert+PSPDFDocument.h"

@implementation RCTConvert (PSPDFAnnotation)

+ (NSArray <NSDictionary *> *)instantJSONFromAnnotations:(NSArray <PSPDFAnnotation *> *) annotations error:(NSError **)error {
  NSMutableArray <NSDictionary *> *annotationsJSON = [NSMutableArray new];
  for (PSPDFAnnotation *annotation in annotations) {
      NSString * base64String=@"";
      if ([annotation isKindOfClass:[PSPDFStampAnnotation class]]) {
          PSPDFStampAnnotation *newStampAnnotation = annotation;
          NSData *imageData = UIImagePNGRepresentation(newStampAnnotation.image);
          base64String = [imageData base64EncodedStringWithOptions:0];
      }
    NSDictionary <NSString *, NSString *> *uuidDict = @{@"uuid" : annotation.uuid};
    NSData *annotationData = [annotation generateInstantJSONWithError:error];
    if (annotationData) {
      NSMutableDictionary *annotationDictionary = [[NSJSONSerialization JSONObjectWithData:annotationData options:kNilOptions error:error] mutableCopy];
     if ([base64String length]>0) {
         [annotationDictionary setObject:base64String forKey:@"binary"];
      }
      [annotationDictionary addEntriesFromDictionary:uuidDict];
      if (annotationDictionary) {
        [annotationsJSON addObject:annotationDictionary];
      }
    } else {
      // We only generate Instant JSON data for attached annotations. When an annotation is deleted, we only set the annotation uuid and name.
      [annotationsJSON addObject:@{@"uuid" : annotation.uuid, @"name" : annotation.name ?: [NSNull null], @"creatorName" : annotation.user ?: [NSNull null]}];
    }
  }
  
  return [annotationsJSON copy];
}

+ (PSPDFAnnotationType)annotationTypeFromInstantJSONType:(NSString *)type {
  if (!type) {
    return PSPDFAnnotationTypeAll;
  } else if ([type isEqualToString:@"pspdfkit/ink"]) {
    return PSPDFAnnotationTypeInk;
  } else if ([type isEqualToString:@"pspdfkit/link"]) {
    return PSPDFAnnotationTypeLink;
  } else if ([type isEqualToString:@"pspdfkit/markup/highlight"]) {
    return PSPDFAnnotationTypeHighlight;
  } else if ([type isEqualToString:@"pspdfkit/markup/squiggly"]) {
    return PSPDFAnnotationTypeSquiggly;
  } else if ([type isEqualToString:@"pspdfkit/markup/strikeout"]) {
    return PSPDFAnnotationTypeStrikeOut;
  } else if ([type isEqualToString:@"pspdfkit/markup/underline"]) {
    return PSPDFAnnotationTypeUnderline;
  } else if ([type isEqualToString:@"pspdfkit/note"]) {
    return PSPDFAnnotationTypeNote;
  } else if ([type isEqualToString:@"pspdfkit/shape/ellipse"]) {
    return PSPDFAnnotationTypeCircle;
  } else if ([type isEqualToString:@"pspdfkit/shape/line"]) {
    return PSPDFAnnotationTypeLine;
  } else if ([type isEqualToString:@"pspdfkit/shape/polygon"]) {
    return PSPDFAnnotationTypePolygon;
  } else if ([type isEqualToString:@"pspdfkit/shape/polyline"]) {
    return PSPDFAnnotationTypePolyLine;
  } else if ([type isEqualToString:@"pspdfkit/shape/rectangle"]) {
    return PSPDFAnnotationTypeSquare;
  } else if ([type isEqualToString:@"pspdfkit/text"]) {
    return PSPDFAnnotationTypeFreeText;
  } else if ([type isEqualToString:@"pspdfkit/stamp"]) {
    return PSPDFAnnotationTypeStamp;
  } else {
    return PSPDFAnnotationTypeUndefined;
  }
}

@end
