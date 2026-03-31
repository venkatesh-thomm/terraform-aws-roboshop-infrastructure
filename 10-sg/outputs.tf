/* 

output "sg_id" {
    value = module.sg[*].sg_id          
} 

*/


/* 
Outputs let Terraform expose data from your module to:The command line (terraform output)
The [*] syntax is the splat operator — it collects a specific attribute from each instance of a module created using count or for_each.
output "sg_id" = ["sg-aaa111", "sg-bbb222"] ----> returning a list of all SG IDs created by the module.
*/
