//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import "ReactiveCocoa.h"
@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;


@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  
  self.signInService = [RWDummySignInService new];
  
  // handle text changes for both text fields

  
  // initially hide the failure message
  self.signInFailureText.hidden = YES;
    
  
    [self practice3];
    
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]
      doNext:^(id x) {
          self.signInButton.enabled = NO;
          self.signInFailureText.hidden = YES;
      } ]
    flattenMap:^id(id value) {
        return [self signInSignal];
    }]
     subscribeNext:^(NSNumber *signedIn){
         BOOL success =[signedIn boolValue];
         self.signInButton.enabled = YES;
         self.signInFailureText.hidden = success;
         if(success){
             [self performSegueWithIdentifier:@"signInSuccess" sender:self];
         }
     }];
}
- (void)practice1 {
        [self.usernameTextField.rac_textSignal subscribeNext:^(id x) {
            NSLog(@"%@",x);
        }];
}
- (void)practice2 {
    [[self.usernameTextField.rac_textSignal filter:^BOOL(NSString *value) {
        NSString *str = value;
        return str.length > 3;
    }] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}
- (void)practice3 {
    RACSignal *validUserNameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *value) {
        return @([self isValidUsername:value]);
    }];
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *value) {
        return @([self isValidPassword:value]);
    }];
    
    RAC(self.usernameTextField,backgroundColor) = [validUserNameSignal map:^id(NSNumber *value) {
        return [value boolValue] ? [UIColor greenColor] : [UIColor yellowColor];
    }];
    RAC(self.passwordTextField,backgroundColor) = [validPasswordSignal map:^id(NSNumber *value) {
        return [value boolValue] ? [UIColor greenColor] : [UIColor yellowColor];
    }];
    
    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validUserNameSignal,validPasswordSignal] reduce:^id(NSNumber*usernameValid, NSNumber *passwordValid){
        return @([usernameValid boolValue] && [passwordValid boolValue]);
    }];
    
    [signUpActiveSignal subscribeNext:^(NSNumber *signUpValid) {
        self.signInButton.enabled = [signUpValid boolValue];
    }];
    
//    [[validPasswordSignal map:^id(NSNumber *value) {
//        return [value boolValue]? [UIColor clearColor]:[UIColor yellowColor];
//    }]
//    subscribeNext:^(UIColor *color) {
//        self.passwordTextField.backgroundColor = color;
//    }];
}
- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}

- (IBAction)signInButtonTouched:(id)sender {
  // disable all UI controls
  self.signInButton.enabled = NO;
  self.signInFailureText.hidden = YES;
  
  // sign in
  [self.signInService signInWithUsername:self.usernameTextField.text
                            password:self.passwordTextField.text
                            complete:^(BOOL success) {
                              self.signInButton.enabled = YES;
                              self.signInFailureText.hidden = success;
                              if (success) {
                                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
                              }
                            }];
}


// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid

#pragma mark - getters and setters
- (RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.signInService signInWithUsername:self.usernameTextField.text password:self.passwordTextField.text complete:^(BOOL success) {
            [subscriber sendNext:@(success)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}
@end
