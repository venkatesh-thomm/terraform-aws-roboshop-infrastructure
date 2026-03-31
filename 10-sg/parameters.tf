resource "aws_ssm_parameter" "sg_id" {                                                 # This creates a new SSM parameter in AWS Parameter Store.
  count = length(var.sg_names)                                                         # create multiple parameters — one per item in the sg_names variable list  
  name  = "/${var.project_name}/${var.environment}/${var.sg_names[count.index]}_sg_id" #   unique SSM parameter name for each SG ;/roboshop/dev/catalogue_sg_id ;/roboshop/dev/cart_sg_id
  type  = "String"
  value = module.sg[count.index].sg_id # actual value being stored — the Security Group ID created by your sg module.
}


/*

Unlike a data block (which reads), this writes/stores values.
Each count.index corresponds to the same index in the sg_names list, so names and IDs align properly.

var.sg_names = ["catalogue", "cart"]

your SG module outputs:

module.sg[0].sg_id = sg-aaa111
module.sg[1].sg_id = sg-bbb222

Then Terraform creates two SSM parameters:

Parameter Name	                 Value
/roboshop/dev/catalogue_sg_id	sg-aaa111
/roboshop/dev/cart_sg_id	    sg-bbb222

*/
