//
//  ViewController.m
//  BankCardNumberFormat
//
//  Created by yxhe on 16/5/4.
//  Copyright © 2016年 yxhe. All rights reserved.
//

#import "ViewController.h"

#define DIGIT_MAX 19   //the macro for the max number of card digits


@interface ViewController ()
{
    UIButton *submitBtn; //the submit button
}

@property (nonatomic, strong) UITextField *bankCardNumberText; //the bankcard number input textfield

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //initialize the textField
    _bankCardNumberText = [[UITextField alloc] init]; //use variable
    [self.bankCardNumberText setFrame:CGRectMake(self.view.frame.size.width/2 - 140, 100, 280, 30)]; //use property method
    self.bankCardNumberText.borderStyle = UITextBorderStyleLine; //use the dot operand
    self.bankCardNumberText.keyboardType = UIKeyboardTypeNumberPad;
    self.bankCardNumberText.textAlignment = NSTextAlignmentLeft;
    _bankCardNumberText.placeholder = @"input bankcard number";
    _bankCardNumberText.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    [self.view addSubview:self.bankCardNumberText]; //or use _banckCardNumberText
    self.bankCardNumberText.delegate = self;
    
    
    //initialize the button
    submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 30, 150, 60, 20)];
    [submitBtn setTitle:@"submit" forState:UIControlStateNormal];
    submitBtn.backgroundColor = [UIColor greenColor];
    
    [self.view addSubview:submitBtn];
    [submitBtn addTarget:self action:@selector(onButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - textField delegate methods
//do the formatting while textfield text is changing
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    //only receive number and backspace input, in case some numberPad receive non-number chars such as sougou T_T
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789\b"];
    NSString *checkStr = [self noneSpaseString:string];
    if ([checkStr rangeOfCharacterFromSet:[characterSet invertedSet]].location != NSNotFound)
        return NO;
    
    
    //process the textField text
    NSString* text = textField.text;
    //delete
    if([string length] <= 0) // or [string isEqualToString:'']
    {
        
        NSLog(@"slected range: location %d, length %d", range.location, range.length);
        
        //delete the last char
        if(range.location == text.length - 1) //because already delete one char, so it is text.length - 1
        {
            //actually it will delete twice, first the backspace then delete the space
            if(text.length >=2 && [text characterAtIndex:text.length-2] == ' ')
                [textField deleteBackward];
            
            return YES;
        }
        //delete in the middle
        else
        {
            NSInteger offset = range.location;
            
            NSLog(@"seleted textrange %@", textField.selectedTextRange);
            
            if(range.location < text.length && [text characterAtIndex:range.location - 1] == ' ' /*&& [textField.selectedTextRange isEmpty]*/)
            {
                [textField deleteBackward]; //Remove the character just before the cursor and redisplay the text.
                offset--;
            }
            [textField deleteBackward];
            
            //format the  string
            textField.text = [self parseString:textField.text];
            
            //reset the cursor pos
            UITextPosition *newPos = [textField positionFromPosition:textField.beginningOfDocument offset:offset];
            textField.selectedTextRange = [textField textRangeFromPosition:newPos toPosition:newPos];
            
            
            return NO;
        }
    }
    //insert int tail or in the middle
    else
    {
        
        //limit the number of digits
        //consider the paste and replace several charcters at one time,ex: 135169 -> 14169, that is:6 + 1 - 2 <19
        if([self noneSpaseString:textField.text].length + string.length - range.length > 19)
        {
            NSLog(@"text len: %d, string len: %d, range len: %d", [self noneSpaseString:textField.text].length,
                  string.length, range.length);
            return NO;
        }
        
        [textField insertText:string]; //Add the character text to the cursor and redisplay the text.
        
        //format the string
        textField.text = [self parseString:textField.text];
        
        //move the cursor to the right place
        NSInteger offset = range.location + string.length;
        if(range.location == 4 ||
           range.location  == 9 ||
           range.location == 14 ||
           range.location == 19)
            offset++;
        
        //reset the cursor pos
        UITextPosition *newPos = [textField positionFromPosition:textField.beginningOfDocument offset:offset];
        textField.selectedTextRange = [textField textRangeFromPosition:newPos toPosition:newPos];
        return NO;
    }
    
    return NO;
}



#pragma mark - helper functions
//remove the space of string
-(NSString*)noneSpaseString:(NSString*)string
{
    return [string stringByReplacingOccurrencesOfString:@" " withString:@""];
}

//everytime check the textfield string to format
- (NSString*)parseString:(NSString*)textStr
{
    if (!textStr) {
        return nil;
    }
    NSMutableString *formatTextStr = [NSMutableString stringWithString:[textStr stringByReplacingOccurrencesOfString:@" " withString:@""]];
    
    //insert space in step by step,ex: 123456789015 -> 1234 56789015 -> 1234 5678 9015
    if(formatTextStr.length > 4)
        [formatTextStr insertString:@" " atIndex:4];
    if(formatTextStr.length > 9)
        [formatTextStr insertString:@" " atIndex:9];
    if(formatTextStr.length > 14)
        [formatTextStr insertString:@" " atIndex:14];
    if(formatTextStr.length > 19)
        [formatTextStr insertString:@" " atIndex:19];
    
    return  formatTextStr;
}

//check whether the bankcard is valid using the Luhn algorithm
- (BOOL)isValidBankCard:(NSString *)bankCardNumber
{
    //reverse odd and even sum
    int oddSum = 0;
    int evenSum = 0;
    int Sum = 0;
    
    int len = bankCardNumber.length;
    for(int i = 0; i< len;i++)
    {
        NSString *digitStr = [bankCardNumber substringWithRange:NSMakeRange(len - 1 - i, 1)];
        int digitVal = digitStr.intValue;
        if(i & 0x01)
        {
            digitVal *= 2;
            if(digitVal>=10)
                digitVal -= 9;
            oddSum += digitVal;
        }
        else
            evenSum += digitVal;
    }
    
    Sum = oddSum + evenSum;
    
    if(Sum % 10 == 0)
        return YES;
    else
        return NO;
}


#pragma mark - button event
- (void)onButtonClicked
{
    
    NSLog(@"button clicked");
    
    NSString *bankCard = [self noneSpaseString:self.bankCardNumberText.text];
    NSLog(@"the bankcard number is: %@", bankCard);
    
    //if the bankcardnumber is invalid then pop an alert window
    if(bankCard.length > 0 && [self isValidBankCard:bankCard])
        NSLog(@"valid bankcard");
    else
    {
        UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"alert"
                                                           message:@"invalid bankcard,please input again!"
                                                          delegate:self
                                                 cancelButtonTitle:@"ok"
                                                 otherButtonTitles:nil];
        [alerView show];
        
        NSLog(@"invalid bankcard!");
        
    }
    [_bankCardNumberText resignFirstResponder]; //hide the keyboard

}

@end
