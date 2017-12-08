#import "MyNSMutableAttributedString.h"

@implementation MyNSMutableAttributedString
- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange
{
    [super setAttributes:(NSDictionary *)attributes range:(NSRange)aRange];
    printf("MyNSMutableAttributedString: setAttributes:(NSDictionary *)attributes range:(NSRange)aRange\n");
}

- (void)setAttributedString:(NSAttributedString *)attributedString
{
    [super setAttributedString:(NSAttributedString *)attributedString];
    printf("MyNSMutableAttributedString: setAttributedString:(NSAttributedString *)attributedString\n");
}
- (void)beginEditing
{
    [super beginEditing];
    printf("MyNSMutableAttributedString: beginEditing\n");
}
- (void)endEditing
{
    [super endEditing];
    printf("MyNSMutableAttributedString: endEditing\n");
}
- (void)addAttribute:(NSString *)name
value:(id)value
range:(NSRange)aRange
{
    [super addAttribute:(NSString *)name
                  value:(id)value
                  range:(NSRange)aRange];
    printf("MyNSMutableAttributedString: addAttribute:(NSString *)namevalue:(id)value range:(NSRange)aRange\n");
}
@end
