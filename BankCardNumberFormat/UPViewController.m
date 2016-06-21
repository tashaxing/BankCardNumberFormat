//
//  ViewController.m
//  BankCardNumberFormat
//
//  Created by yxhe on 16/5/4.
//  Copyright © 2016年 yxhe. All rights reserved.
//

#import "UPViewController.h"

/*************global const variables and macros*****/
//the max length of card number
const static int kCardNumberLen       = 19;
//the format space of card number
const static int kCardSpaceStep       = 4;

//the width of textfield
const static float kTextFieldWidth    = 140;
//the width of submit button
const static float kSubmitButtonWidth = 30;

//the exception string
static NSString *kExceptionStr =  @"0123456789\b";
/**************************************************/

@interface UPViewController ()
{
    //the submit button
    UIButton *submitBtn;
}

//the bankcard number input textfield
@property (nonatomic, strong) UITextField *bankCardNumberText;

@end

@implementation UPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //initialize the textField
    _bankCardNumberText = [[UITextField alloc] init]; //use variable
    [self.bankCardNumberText setFrame:CGRectMake(self.view.frame.size.width/2 - kTextFieldWidth,
                                                 100, kTextFieldWidth * 2, 30)];
    self.bankCardNumberText.borderStyle = UITextBorderStyleLine; //use the dot operand
    self.bankCardNumberText.keyboardType = UIKeyboardTypeNumberPad;
    self.bankCardNumberText.textAlignment = NSTextAlignmentLeft;
    _bankCardNumberText.placeholder = @"input bankcard number";
    _bankCardNumberText.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    [self.view addSubview:self.bankCardNumberText];
    self.bankCardNumberText.delegate = self;
    
    //initialize the button
    submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - kSubmitButtonWidth,
                                                           150, kSubmitButtonWidth * 2, 20)];
    [submitBtn setTitle:@"submit" forState:UIControlStateNormal];
    submitBtn.backgroundColor = [UIColor greenColor];
    
    [self.view addSubview:submitBtn];
    [submitBtn addTarget:self action:@selector(onSubmitButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - textField delegate methods
//do the formatting while textfield text is changing
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // -----filter the invalid chars
    // only receive number and backspace input, in case some numberPad receive non-number chars such as sougou T_T
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:kExceptionStr];
    NSString *checkStr = [self trimCardNumber:string];
    if ([checkStr rangeOfCharacterFromSet:[characterSet invertedSet]].location != NSNotFound)
        return NO;
    
    // -----process the textField text
    BOOL ret = NO;
    if([string length] <= 0)
    {
        // if received the backspace then delete one char
        NSString* text = textField.text;
        NSLog(@"slected range: location %ld, length %ld", range.location, range.length);
        
        if(range.location == text.length - 1)
        {
            // delete the last char, because already delete one char, so it is text.length - 1
            
            //actually it will delete twice, first the backspace then delete the space
            if(text.length >=2 && [text characterAtIndex:text.length-2] == ' ')
            {
                [textField deleteBackward];
            }
            
            
            //must return YES here
            ret = YES;
        }
        else
        {
            // delete in the middle
            
            NSInteger offset = range.location;
            
            NSLog(@"seleted textrange %@", textField.selectedTextRange);
            
            if(range.location < text.length && [text characterAtIndex:range.location - 1] == ' ')
            {
                // Remove the character just before the cursor and redisplay the text.
                [textField deleteBackward];
                offset--;
            }
            [textField deleteBackward];
            
            //format the  string
            textField.text = [self formatCardNumber:textField.text];
            
            //reset the cursor pos
            UITextPosition *newPos = [textField positionFromPosition:textField.beginningOfDocument offset:offset];
            textField.selectedTextRange = [textField textRangeFromPosition:newPos toPosition:newPos];
        }
    }
    else
    {
        // insert chars in tail or in the middle
        
        NSLog(@"text len: %ld, string len: %ld, range len: %ld", [self trimCardNumber:textField.text].length,
              string.length, range.length);
        //limit the number of digits
        //consider the paste and replace several charcters at one time,ex: 135169 -> 14169, that is:6 + 1 - 2 <19
        NSInteger editedCardNumberLen = [self trimCardNumber:textField.text].length + string.length - range.length;
        if(editedCardNumberLen <= kCardNumberLen)
        {
            //add the character text to the cursor and redisplay the text
            [textField insertText:string];
            
            //format the string
            textField.text = [self formatCardNumber:textField.text];
            
            //move the cursor to the new location
            NSInteger offset = range.location + string.length;
            for(int newLocation = kCardSpaceStep; newLocation <= kCardNumberLen; newLocation += (kCardSpaceStep + 1))
            {
                if(range.location == newLocation)
                {
                    offset++;
                    break;
                }
            }
            
            //reset the cursor pos
            UITextPosition *newPos = [textField positionFromPosition:textField.beginningOfDocument offset:offset];
            textField.selectedTextRange = [textField textRangeFromPosition:newPos toPosition:newPos];
        }
    }
    
    return ret;
}

#pragma mark - button events
- (void)onSubmitButtonClicked
{
    
    NSLog(@"button clicked");
    
    NSString *bankCard = [self trimCardNumber:self.bankCardNumberText.text];
    NSLog(@"the bankcard number is: %@", bankCard);
    
    // -----check the card number
    
    if(bankCard.length > 0 && [self isValidCardNumber:bankCard])
    {
        NSLog(@"valid bankcard");
        //do sth to handle the valid cardnumber...
        
    }
    else
    {
        //if the bankcardnumber is invalid then pop an alert window
        UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"alert"
                                                           message:@"invalid bankcard,please input again!"
                                                          delegate:self
                                                 cancelButtonTitle:@"ok"
                                                 otherButtonTitles:nil];
        [alerView show];
        
        NSLog(@"invalid bankcard!");
        
    }
    //hide the keyboard
    [_bankCardNumberText resignFirstResponder];
    
}

#pragma mark - helper functions
//remove the space of string
- (NSString*)trimCardNumber:(NSString*)cardNumber
{
    return [cardNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
}

//everytime check the textfield string to format
- (NSString*)formatCardNumber:(NSString*)cardNumber
{
    if (!cardNumber)
    {
        return nil;
    }
    
    NSMutableString *formatCardNumber = [NSMutableString stringWithString:[cardNumber stringByReplacingOccurrencesOfString:@" " withString:@""]];
    
    //insert space step by step,ex: 123456789015 -> 1234 56789015 -> 1234 5678 9015
    int insertPos = kCardSpaceStep;
    while(formatCardNumber.length > insertPos)
    {
        [formatCardNumber insertString:@" " atIndex:insertPos];
        insertPos += (kCardSpaceStep + 1);
    }
    
    return formatCardNumber;
}

//check whether the bankcard is valid using the Luhn algorithm
- (BOOL)isValidCardNumber:(NSString *)cardNumber
{
    //reverse odd and even sum
    int oddSum = 0;
    int evenSum = 0;
    int sum = 0;
    
    int len = (int)cardNumber.length;
    for(int i = 0; i< len;i++)
    {
        NSString *digitStr = [cardNumber substringWithRange:NSMakeRange(len - 1 - i, 1)];
        int digitVal = digitStr.intValue;
        if(i & 0x01)
        {
            digitVal *= 2;
            if(digitVal>=10)
            {
                digitVal -= 9;
            }
            oddSum += digitVal;
        }
        else
        {
            evenSum += digitVal;
        }
    }
    
    sum = oddSum + evenSum;
    
    return (sum % 10 == 0);
}

@end
